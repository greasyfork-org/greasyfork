require 'match_uri'

class CssParser
  META_START_COMMENT = '/* ==UserStyle=='.freeze
  META_END_COMMENT = '==/UserStyle== */'.freeze

  CssDocumentBlock = Struct.new(:matches, :start_pos, :end_pos)
  CssDocumentMatch = Struct.new(:rule_type, :value)

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
        meta_match = /@([a-zA-Z:-]+)\s+(.*)/.match(meta_line)
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
        meta_match = /\s*@([a-zA-Z]+)\s+(.*)/.match(meta_line)
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
        new_lines = replacements.compact.map { |k, v| "@#{k} #{v}" }
        close_meta = meta_lines.pop
        meta_lines.concat(new_lines)
        meta_lines << close_meta
      end

      code_blocks = get_code_blocks(code)
      return code_blocks[0] + meta_lines.join("\n") + code_blocks[1]
    end

    def calculate_applies_to_names(code)
      parse_doc_blocks(code)
        .map(&:first)
        .flatten
        .map { |css_document_match| convert_for_applies_to_name(css_document_match) }
        .uniq
    end

    def parse_doc_blocks(code, calculate_block_positions: false)
      # XXX This should be a real parser, whether a gem or custom-made. This is not properly handling
      # comments or stuff inside other strings.

      unless code.include?('@-moz-document')
        # It's all global. Return one block with whitespace stripped.
        stripped_code = code.strip
        start = code.index(stripped_code)
        return [CssDocumentBlock.new([], start, start + stripped_code.length - 1)]
      end

      matches = []
      s = StringScanner.new(code)
      next_block_start = 0

      while s.skip_until(/@-moz-document/)
        matches << CssDocumentBlock.new([], next_block_start, s.charpos - 15) # '@-moz-document'.length - 1

        block_matches = []
        s.skip(/\s*/)
        while (rule_type = s.scan(/(domain|url|url-prefix|regexp)\s*\(/))
          rule_type.sub!(/\s*\(/, '')
          s.skip(/\s*/)
          quote = s.scan(/['"]/)
          ending_pattern = if quote
                             Regexp.new("#{quote}\\s*\\)")
                           else
                             /\)/
                           end
          value = s.scan_until(ending_pattern)
          value = value.sub(Regexp.union(ending_pattern, /\z/), '')
          block_matches << CssDocumentMatch.new(rule_type, value)
          s.skip(/\s*,\s*/)
        end

        if calculate_block_positions
          # At this point the @-moz-document is open to open its bracket.
          s.skip(/\s*\{/)
          start_pos = s.charpos

          bracket_count = 1

          until bracket_count == 0 || s.eos?
            # Count opening and closing brackets. Would get totally borked by comments or brackets in strings.
            up_to_next_bracket = s.scan_until(/[{}]/)
            break if up_to_next_bracket.nil? # Unclosed bracket, move on.

            bracket = up_to_next_bracket[-1]
            if bracket == '{'
              bracket_count += 1
            else
              bracket_count -= 1
            end
          end
          matches << CssDocumentBlock.new(block_matches, start_pos, s.charpos - bracket.length - 1)
        else
          matches << CssDocumentBlock.new(block_matches, nil, nil)
        end

        next_block_start = s.charpos
      end
      matches
    end

    def convert_for_applies_to_name(css_document_match)
      case css_document_match.rule_type
      when 'regexp'
        return { text: css_document_match.value, domain: false, tld_extra: false }
      when 'domain'
        # Don't return it as a domain unless it looks like a valid domain.
        return { text: MatchUri.get_tld_plus_1(css_document_match.value), domain: true, tld_extra: false } if JsParser::VALID_DOMAIN_REGEXP.match?(css_document_match.value)

        return { text: css_document_match.value, domain: false, tld_extra: false }
      else
        begin
          uri = URI(css_document_match.value)
        rescue ArgumentError, URI::InvalidURIError
          Rails.logger.warn "Invalid URI '#{css_document_match.value}'"
          return { text: css_document_match.value + ((css_document_match.rule_type == 'url-prefix') ? '*' : ''), domain: false, tld_extra: false }
        else
          if uri.host.nil?
            return { text: css_document_match.value + ((css_document_match.rule_type == 'url-prefix') ? '*' : ''), domain: false, tld_extra: false }
          end
          if uri.host.exclude?('.') || uri.host.include?('*')
            # ensure the host is something sane
            return { text: css_document_match.value + ((css_document_match.rule_type == 'url-prefix') ? '*' : ''), domain: false, tld_extra: false }
          end

          return { text: MatchUri.get_tld_plus_1(uri.host), domain: true, tld_extra: false }
        end
      end
    end
  end
end
