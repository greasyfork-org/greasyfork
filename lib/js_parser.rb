require 'match_uri'
require 'url_regexp'

class JsParser
  META_START_COMMENT = '// ==UserScript=='.freeze
  META_END_COMMENT = '// ==/UserScript=='.freeze

  TLD_EXPANSION = ['com', 'net', 'org', 'de', 'co.uk'].freeze
  APPLIES_TO_ALL_PATTERNS = ['http://*', 'https://*', 'http://*/*', 'https://*/*', 'http*://*', 'http*://*/*', '*', '*://*', '*://*/*', 'http*'].freeze

  # Include * in this too as that's allowed in various scenarios
  VALID_DOMAIN_REGEXP = /\A[a-z0-9\-.\*]+\z/i

  class << self
    def get_meta_block(code)
      return nil if code.nil?

      start_block = code.index(META_START_COMMENT)
      return nil if start_block.nil?

      end_block = code.index(META_END_COMMENT, start_block)
      return nil if end_block.nil?

      return code[start_block..end_block + META_END_COMMENT.length]
    end

    # Returns the meta for this script in a hash of key to array of values
    def parse_meta(code)
      meta = {}
      meta_block = get_meta_block(code)
      return meta if meta_block.nil?

      # can these be multiline?
      meta_block.split("\n").each do |meta_line|
        meta_match = %r{//\s+@([a-zA-Z:-]+)\s+(.*)}.match(meta_line)
        next if meta_match.nil?

        key = meta_match[1].strip
        value = meta_match[2].strip
        if meta.key?(key)
          meta[key] << value
        else
          meta[key] = [value]
        end
      end
      return meta
    end

    # Returns a two-element array: code before the meta block, code after
    def get_code_blocks(code)
      meta_start = code.index(META_START_COMMENT)
      return [code, ''] if meta_start.nil?

      meta_end_start = code.index(META_END_COMMENT, meta_start)
      return [code, ''] if meta_end_start.nil?

      meta_end = meta_end_start + META_END_COMMENT.length
      return [((meta_start == 0) ? '' : code[0..meta_start - 1]), code[meta_end..code.length]]
    end

    # Inserts, changes, or deletes meta values in the code and returns the entire code
    def inject_meta(code, replacements, additions_if_missing = {})
      meta_block = get_meta_block(code)
      return nil if meta_block.nil?

      # handle strings or symbols as the keys
      replacement_keys = replacements.keys.map(&:to_s)
      replacements = replacements.with_indifferent_access
      additions_if_missing = additions_if_missing.with_indifferent_access
      # replace any existing values
      meta_lines = meta_block.split("\n").map do |meta_line|
        meta_match = %r{//\s+@([a-zA-Z]+)\s+(.*)}.match(meta_line)
        next meta_line if meta_match.nil?

        key = meta_match[1].strip
        value = meta_match[2].strip
        additions_if_missing.delete(key)
        # replace the first one, remove any subsequent ones
        if replacement_keys.include?(key)
          if replacements.key?(key) && !value.nil?
            replacement = replacements.delete(key)
            next nil if replacement.nil?

            next meta_line.sub(value, replacement)
          end
          next nil
        end
        next meta_line
      end

      meta_lines.compact!

      # add new values
      replacements.update(additions_if_missing)
      unless replacements.empty?
        # nils here would indicate a removal that wasn't there, so ignore that
        new_lines = replacements.compact.map { |k, v| "// @#{k} #{v}" }
        close_meta = meta_lines.pop
        meta_lines.concat(new_lines)
        meta_lines << close_meta
      end

      code_blocks = get_code_blocks(code)
      return code_blocks[0] + meta_lines.join("\n") + code_blocks[1]
    end

    APPLIES_TO_META_KEYS = %w[include match].freeze

    # Returns an object with:
    # - :text
    # - :domain - boolean - is text a domain?
    # - :tld_extra - boolean - is this extra entries added because of .tld?
    def calculate_applies_to_names(code)
      meta = parse_meta(code)
      patterns = []
      meta.each { |k, v| patterns.concat(v) if APPLIES_TO_META_KEYS.include?(k) }

      return [] if patterns.empty?
      return [] if patterns.intersect?(APPLIES_TO_ALL_PATTERNS)

      applies_to_names = []
      patterns.each do |p|
        original_pattern = p

        pre_wildcards = []
        # regexp - starts and ends with /
        if p.match(%r{^/.*/$}).present?
          begin
            Timeout.timeout(0.1) do
              pre_wildcards = UrlRegexp.expand(p[1..-2])
            end
          rescue Timeout::Error
            Rails.logger.error("Timeout parsing regexp #{p}")
          rescue StandardError => e
            Rails.logger.error("Error parsing regexp #{p}: #{e}")
          end
        else

          # senseless wildcard before protocol
          m = p.match(/^\*(https?:.*)/i)
          p = m[1] unless m.nil?

          # protocol wild-cards
          p = p.sub(/^\*:/i, 'http:')
          p = p.sub(%r{^\*//}i, 'http://')
          p = p.sub(/^http\*:/i, 'http:')

          # skipping the protocol slashes
          p = p.sub(%r{^(https?):([^/])}i, '\1://\2')

          # subdomain wild-cards - http://*.example.com and http://*example.com
          m = p.match(%r{^([a-z]+://)\*\.?([a-z0-9-]+(?:.[a-z0-9-]+)+.*)}i)
          p = m[1] + m[2] unless m.nil?

          # protocol and subdomain wild-cards - *example.com and *.example.com
          m = p.match(/^\*\.?([a-z0-9-]+\.[a-z0-9-]+.*)/i)
          p = "http://#{m[1]}" unless m.nil?

          # protocol and subdomain wild-cards - http*.example.com, http*example.com, http*//example.com
          m = p.match(%r{^http\*(?://)?\.?((?:[a-z0-9-]+)(?:\.[a-z0-9-]+)+.*)}i)
          p = "http://#{m[1]}" unless m.nil?

          # tld wildcards - http://example.* - switch to .tld. don't switch if it's an ip address, though
          m = p.match(%r{^([a-z]+://([a-z0-9-]+(?:\.[a-z0-9-]+)*\.))\*(.*)})
          if !m.nil? && m[2].match(/\A([0-9]+\.){2,}\z/).nil?
            p = "#{m[1]}tld#{m[3]}"
            # grab up to the first *
            pre_wildcards = [p.split('*').first]
          else
            pre_wildcards = [p]
          end
        end

        pre_wildcards.each do |pre_wildcard|
          uri = URI(pre_wildcard)
          if uri.host.nil?
            applies_to_names << { text: original_pattern, domain: false, tld_extra: false }
          elsif uri.host.exclude?('.') || uri.host.include?('*') || !uri.host.match?(VALID_DOMAIN_REGEXP)
            # ensure the host is something sane
            applies_to_names << { text: original_pattern, domain: false, tld_extra: false }
          elsif uri.host.ends_with?('.tld')
            TLD_EXPANSION.each_with_index do |tld, i|
              applies_to_names << { text: MatchUri.get_tld_plus_1(uri.host.sub(/tld$/i, tld)), domain: true, tld_extra: i != 0 }
            end
            # "example.com."
          elsif uri.host.ends_with?('.')
            applies_to_names << { text: MatchUri.get_tld_plus_1(uri.host[0, uri.host.length - 1]), domain: true, tld_extra: false }
          else
            applies_to_names << { text: MatchUri.get_tld_plus_1(uri.host), domain: true, tld_extra: false }
          end
        rescue ArgumentError, URI::InvalidURIError
          Rails.logger.warn "Unrecognized pattern '#{p}'"
          applies_to_names << { text: original_pattern, domain: false, tld_extra: false }
        end
      end
      # If there's a tld_extra and a not-tld_extra for the same text, remove the tld_extra
      applies_to_names.delete_if { |h1| h1[:tld_extra] && applies_to_names.any? { |h2| !h2[:tld_extra] && h1[:text] == h2[:text] } }
      # Then make sure we're unique
      return applies_to_names.uniq
    end
  end
end
