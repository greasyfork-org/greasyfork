require 'open-uri'

module ScriptImporter
  class BaseScriptImporter
    def self.can_handle_url(_url)
      raise 'Missing'
    end

    def self.import_source_name
      raise 'Missing'
    end

    # Generates a script list and returns an array:
    # - Result code:
    #   - :failure
    #   - :notuserscript
    #   - :needsdescription
    #   - :success
    # - The script
    # - An error message
    def self.generate_script(sync_id, provided_description, user, sync_type = 'manual', localized_attribute_syncs = {}, locale = nil, do_not_recheck_if_equal_to: nil, expected_language: nil, expected_script_type: :public, existing_script_id: nil)
      sync_id = fix_sync_id(sync_id)
      begin
        code = download(sync_id)
      rescue OpenURI::HTTPError, Errno::ETIMEDOUT => e
        return [:failure, nil, "Could not download source. #{e.message}"]
      rescue Timeout::Error
        return [:failure, nil, 'Could not download source. Download did not complete in allowed time.']
      rescue StandardError => e
        return [:failure, nil, "Could not download source. #{e.message}"]
      end
      # Tests use frozen strings, and can't use force_encoding on those.
      code = code.dup if code.frozen?
      code = code.force_encoding(Encoding::UTF_8)
      return [:failure, nil, 'Source contains invalid UTF-8 characters.'] unless code.valid_encoding?

      sv = ScriptVersion.new
      sv.code = code
      sv.changelog = "Imported from #{import_source_name}"

      script = Script.new
      script.id = existing_script_id
      script.authors.build(user:)
      script.script_type = expected_script_type
      script.sync_type = sync_type
      script.language = expected_language || (sync_id.ends_with?('.css') ? 'css' : 'js')
      script.locale = locale
      script.sync_identifier = sync_id
      script.last_attempted_sync_date = DateTime.now
      script.last_successful_sync_date = DateTime.now

      # now get the additional infos
      localized_attribute_syncs.each do |la|
        new_la = sv.build_localized_attribute(la)
        next if la.sync_identifier.nil?

        begin
          ai = ScriptSyncer.choose_importer.download(la.sync_identifier)
          # We don't have the ability to adjust the Markdown to absolutize the references, so we do that at render time.
          if la.value_markup == 'html'
            absolute_ai = absolutize_references(ai, la.sync_identifier)
            ai = absolute_ai unless absolute_ai.nil?
          end
          new_la.attribute_value = ai
        rescue StandardError => e
          # if something fails here, we'll just ignore.
          next
        end
      end

      sv.script = script
      script.script_versions << sv
      sv.do_lenient_saving
      sv.calculate_all(provided_description)
      script.apply_from_script_version(sv)

      return [:notuserscript, script, script.js? ? 'Does not appear to be a user script.' : 'Does not appear to be a user style.'] if !script.library? && script.name.nil?

      return [:needsdescription, script, nil] if script.description.blank?

      # prefer script_version error messages, but show script error messages if necessary
      return [:failure, script, (sv.errors.full_messages.empty? ? script.errors.full_messages : sv.errors.full_messages).join(', ')] if !script.valid? | !sv.valid?

      if do_not_recheck_if_equal_to.nil? || code != do_not_recheck_if_equal_to
        script_check_results, script_check_result_code = ScriptCheckingService.check(sv)

        return [:failure, script, script_check_results.first.public_reason] if [ScriptChecking::Result::RESULT_CODE_BAN, ScriptChecking::Result::RESULT_CODE_BLOCK].include?(script_check_result_code)

        script.review_state = 'required' if script_check_result_code == ScriptChecking::Result::RESULT_CODE_REVIEW
      end

      return [:success, script, nil]
    end

    def self.download(url)
      # make_regexp seems to allow some non http(s) URLs, so explicitly check the scheme too
      raise ArgumentError, 'URL must be http or https' unless url&.match?(URI::DEFAULT_PARSER.make_regexp(%w[http https])) && (url.starts_with?('http:') || url.starts_with?('https:'))

      uri = URI.parse(url)
      Timeout.timeout(11) do
        return uri.read({ read_timeout: 10 })
      end
    end

    # updates the URL to the working version
    def self.fix_sync_id(sync_id)
      sync_id
    end

    def self.absolutize_references(html, base)
      changed = false
      base_url = URI.parse(base)
      tags = { 'img' => 'src', 'a' => 'href' }
      doc = Nokogiri::HTML.fragment(html)
      doc.search(tags.keys.join(',')).each do |node|
        url_param = tags[node.name]
        url_text = node[url_param]
        next unless url_text
        next if url_text.starts_with?('#')

        begin
          new_url = base_url.merge(url_text)
          if url_text != new_url.to_s
            changed = true
            node[url_param] = new_url
          end
        rescue URI::InvalidURIError
          # Leave as is
        end
      end
      return html unless changed

      return doc.to_html
    end
  end
end
