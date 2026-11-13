require 'securerandom'
require 'English'

class ElasticsearchCodeSearch
  class AlreadyRunningError < RuntimeError; end
  class SearchTimeoutError < RuntimeError; end

  BATCH_SIZE = 100
  MAX_BATCH_BYTES = 4.megabytes
  SCROLL_SIZE = 10_000
  SCROLL_KEEPALIVE = '2m'.freeze
  SEARCH_TIMEOUT = 35

  class << self
    def index_name
      "script_code_search_#{Rails.env}"
    end

    def index_all
      with_index_lock(timeout: 0) { rebuild }
    end

    def index_script(script_id)
      with_index_lock(timeout: 10) do
        client = Searchkick.client
        raise "Elasticsearch code search index #{index_name} has not been built" unless client.indices.exists_alias(name: index_name)

        code = ScriptVersion.where(script_id:).order(id: :desc).joins(:script_code).pick('script_codes.code')
        if code
          client.index(index: index_name, id: script_id, require_alias: true, body: { code: })
        else
          client.delete(index: index_name, id: script_id, ignore: [404])
        end
      end
    end

    def delete_old_index(old_index)
      raise "Invalid Elasticsearch code search index: #{old_index}" unless old_index.match?(/\A#{Regexp.escape(index_name)}_[0-9a-f]{16}\z/)

      client = Searchkick.client
      return unless client.indices.exists(index: old_index)
      raise "Cannot delete active code search index: #{old_index}" if client.indices.exists_alias(index: old_index, name: index_name)

      stats = client.indices.stats(index: old_index, metric: 'search')
      if stats.dig('_all', 'total', 'search', 'open_contexts').to_i.positive?
        ElasticsearchCodeSearchCleanupJob.set(wait: 2.minutes).perform_later(old_index)
      else
        client.indices.delete(index: old_index)
      end
    end

    private

    def with_index_lock(timeout:)
      # Updates must not overtake each other or the rebuild's alias switch.
      connection = Script.connection
      lock_name = connection.quote(index_name)
      acquired = connection.uncached { connection.select_value("SELECT GET_LOCK(#{lock_name}, #{timeout})") }
      raise AlreadyRunningError, 'Elasticsearch code search rebuild or update is already running' unless acquired == 1

      begin
        yield
      ensure
        released = connection.uncached { connection.select_value("SELECT RELEASE_LOCK(#{lock_name})") }
        raise 'Failed to release Elasticsearch code search rebuild lock' unless released == 1
      end
    end

    def rebuild
      client = Searchkick.client
      new_index = "#{index_name}_#{SecureRandom.hex(8)}"
      created = false
      published = false

      client.indices.create(index: new_index, body: {
                              settings: { number_of_shards: 1, number_of_replicas: 0, refresh_interval: '-1' },
                              mappings: { properties: { code: { type: 'wildcard' } } },
                            })
      created = true

      last_script_id = 0
      indexed_count = 0
      loop do
        rows = Script.connection.select_rows(<<~SQL.squish)
          SELECT sv.script_id, sc.code
          FROM script_versions sv
          INNER JOIN (
            SELECT script_id, MAX(id) AS latest_id
            FROM script_versions
            WHERE script_id > #{last_script_id}
            GROUP BY script_id
            ORDER BY script_id
            LIMIT #{BATCH_SIZE}
          ) latest ON latest.latest_id = sv.id
          INNER JOIN script_codes sc ON sc.id = sv.script_code_id
          ORDER BY sv.script_id
        SQL
        break if rows.empty?

        body = []
        batch_bytes = 0
        rows.each do |script_id, code|
          if body.any? && batch_bytes + code.bytesize > MAX_BATCH_BYTES
            index_batch(client, new_index, body)
            body = []
            batch_bytes = 0
          end
          body << { index: { _id: script_id } } << { code: }
          batch_bytes += code.bytesize
        end
        index_batch(client, new_index, body) if body.any?
        last_script_id = rows.last.first
        indexed_count += rows.length
        Rails.logger.info("Elasticsearch code search indexed #{indexed_count} scripts") if (indexed_count % 10_000).zero?
      end

      client.indices.put_settings(index: new_index, body: { index: { refresh_interval: '1s' } })
      client.indices.refresh(index: new_index)
      old_indices = client.indices.exists_alias(name: index_name) ? client.indices.get_alias(name: index_name).keys : []
      raise "Unexpected indices behind code search alias: #{old_indices.inspect}" unless old_indices.all? { |name| /\A#{Regexp.escape(index_name)}_[0-9a-f]{16}\z/.match?(name) }

      actions = old_indices.map { |name| { remove: { index: name, alias: index_name } } }
      actions << { add: { index: new_index, alias: index_name } }
      client.indices.update_aliases(body: { actions: })
      published = true
      Rails.logger.info("Elasticsearch code search index rebuilt: #{new_index}")
      old_indices.each { |old_index| ElasticsearchCodeSearchCleanupJob.set(wait: 2.minutes).perform_later(old_index) }
    ensure
      client.indices.delete(index: new_index) if created && !published
    end

    public

    def search(text, limit_to_ids: nil)
      CodeSearchQuery.validate!(text)
      return [] if limit_to_ids&.none?

      pattern = text.gsub(/[\\*?]/) { |character| "\\#{character}" }
      query = { wildcard: { code: { value: "*#{pattern}*" } } }
      query = { bool: { filter: [query, { ids: { values: limit_to_ids } }] } } unless limit_to_ids.nil?
      client = search_client
      scroll_id = nil
      page_count = 0
      ids = []
      begin
        CodeSearchTiming.measure('Elasticsearch') do
          response = measure_request('initial') do
            client.search(index: index_name, scroll: SCROLL_KEEPALIVE, body: {
                            size: SCROLL_SIZE,
                            sort: ['_doc'],
                            _source: false,
                            query:,
                          })
          end
          scroll_id = response['_scroll_id']
          loop do
            raise SearchTimeoutError, 'Elasticsearch code search timed out' if response['timed_out']
            raise "Elasticsearch code search failed: #{response.inspect}" if response.dig('_shards', 'failed').to_i.positive?

            hits = response.fetch('hits').fetch('hits')
            break if hits.empty?

            page_count += 1
            hits.each { |hit| ids << Integer(hit.fetch('_id')) }
            raise 'Elasticsearch code search did not return a scroll ID' if scroll_id.blank?

            response = measure_request('scroll') { client.scroll(scroll_id:, scroll: SCROLL_KEEPALIVE) }
            scroll_id = response['_scroll_id'] || scroll_id
          end
          ids
        ensure
          Rails.logger.info("Elasticsearch code search query_length=#{text.length} filter_ids=#{limit_to_ids&.length || 'none'} pages=#{page_count} hits=#{ids.length}")
        end
      rescue Elastic::Transport::Transport::Error => e
        raise SearchTimeoutError, 'Elasticsearch code search timed out' if timeout_error?(e)

        raise
      ensure
        if scroll_id.present?
          original_error = $ERROR_INFO
          begin
            client.clear_scroll(body: { scroll_id: [scroll_id] })
          rescue StandardError => e
            unless original_error
              raise SearchTimeoutError, 'Elasticsearch code search timed out' if timeout_error?(e)

              raise
            end
            Rails.logger.error("Elasticsearch code search scroll cleanup failed: #{e.class}: #{e.message}")
            Sentry.capture_exception(e)
          end
        end
      end
    end

    private

    def timeout_error?(error)
      while error
        return true if error.is_a?(Faraday::TimeoutError) || error.is_a?(Net::ReadTimeout)

        error = error.cause
      end
      false
    end

    def search_client
      @search_client ||= begin
        options = { url: ENV['ELASTICSEARCH_URL'] }.deep_merge(Searchkick.client_options)
        options.delete(:request_timeout)
        options.deep_merge!(
          retry_on_failure: 0,
          retry_on_status: [],
          reload_on_failure: false,
          transport_options: { request: { timeout: SEARCH_TIMEOUT, read_timeout: SEARCH_TIMEOUT } }
        )
        Elasticsearch::Client.new(options) do |faraday|
          faraday.use Searchkick::Middleware
          faraday.request :aws_sigv4, Searchkick.signer_middleware_aws_params if Searchkick.aws_credentials
        end
      end
    end

    def measure_request(phase)
      CodeSearchTiming.measure("Elasticsearch #{phase}") do
        response = yield
        Rails.logger.info("Elasticsearch code search phase=#{phase} took_ms=#{response['took']} hits=#{response.dig('hits', 'hits')&.length}")
        response
      end
    end

    def index_batch(client, index, body)
      response = client.bulk(index:, body:)
      return unless response['errors']

      errors = response.fetch('items').filter_map { |item| item.fetch('index')['error'] }
      raise "Code search indexing failed: #{errors.first(5).inspect}"
    end
  end
end
