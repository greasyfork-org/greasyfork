require 'css_parser'

class CssToJsConverter
  class << self
    include ActionView::Helpers::JavaScriptHelper

    VERBATIM_META_LINES = %w[name version namespace description author homepageURL supportURL license].freeze

    def convert(css)
      code_css = CssParser.get_code_blocks(css).join("\n")
      doc_blocks_and_code = CssParser.parse_doc_blocks(code_css, calculate_block_positions: true)
                                     .map { |doc_block| [doc_block, code_css[doc_block.start_pos..doc_block.end_pos]] }
                                     .reject { |_doc_block, block_code| block_code.blank? }

      if doc_blocks_and_code.count > 1
        doc_blocks_and_code = doc_blocks_and_code.reject do |doc_block, block_code|
          doc_block.matches.none? && only_comments?(block_code)
        end
      end

      meta = CssParser.parse_meta(css).select { |k, _v| VERBATIM_META_LINES.include?(k) }
      meta['grant'] = ['GM_addStyle']
      meta['run-at'] = ['document-start']
      meta['include'] = calculate_includes(doc_blocks_and_code.map(&:first))

      lines = [
        '// ==UserScript==',
      ] + meta.map { |key, values| values.map { |value| "// @#{key} #{value}" } } + [
        '// ==/UserScript==',
        '',
        '(function() {',
      ]

      if doc_blocks_and_code.length == 1 && (meta['include'] != ['*'] || doc_blocks_and_code.first.first.matches.empty?)
        # 0 or 1 document block, and we correctly encoded it as an include. No need for conditionals.
        lines << "let css = `#{escape_for_js_literal(doc_blocks_and_code.first.last)}`;"
      else
        lines << 'let css = "";'
        lines += doc_blocks_and_code.map do |doc_block, block_code|
          js_for_block = "css += `#{escape_for_js_literal(block_code)}`;"
          next js_for_block if doc_block.matches.empty?

          conditions = doc_block.matches.map do |match|
            case match.rule_type
            when 'url'
              "location.href === \"#{j match.value}\""
            when 'url-prefix'
              "location.href.startsWith(\"#{j match.value}\")"
            when 'domain'
              "(location.hostname === \"#{j match.value}\" || location.hostname.endsWith(\".#{j match.value}\"))"
            when 'regexp'
              "new RegExp(\"#{j match.value}\").test(location.href)"
            end
          end
          ["if (#{conditions.join(' || ')}) {", js_for_block.indent(2), '}']
        end
      end
      lines << <<~JS.strip
        if (typeof GM_addStyle !== "undefined") {
          GM_addStyle(css);
        } else {
          let styleNode = document.createElement("style");
          styleNode.appendChild(document.createTextNode(css));
          (document.querySelector("head") || document.documentElement).appendChild(styleNode);
        }
      JS
      lines << '})();'
      "#{lines.flatten.join("\n")}\n"
    end

    def j(code)
      escape_javascript(code)
    end

    def calculate_includes(doc_blocks)
      # If there's any without a specific rule, it'll be global.
      return ['*'] if doc_blocks.any? { |doc_block| doc_block.matches.empty? }

      matches = doc_blocks
                .map(&:matches)
                .flatten
                .group_by(&:rule_type)
                .transform_values { |m| m.map(&:value).uniq }

      %w[regexp domain url url-prefix].each { |rule_type| matches[rule_type] = [] unless matches.key?(rule_type) }

      js_includes = matches['regexp'].map { |re| "/#{re}/" }
      js_includes += matches['domain'].map { |domain| [domain, "*.#{domain}"].map { |d| ["http://#{d}/*", "https://#{d}/*"] } }.flatten

      # Don't include url or url-prefix if already covered by a domain rule.
      %w[url url-prefix].each do |rule_type|
        url_and_prefix_rules = matches[rule_type].select do |value|
          uri = URI(value)
        rescue ArgumentError, URI::InvalidURIError
          next true
        else
          next true if uri.host.nil?

          next matches['domain'].exclude?(uri.host)
        end
        js_includes += url_and_prefix_rules.map { |value| value + (rule_type == 'url-prefix' ? '*' : '') }
      end

      js_includes.uniq
    end

    def only_comments?(css)
      %r{\A(\s*/\*.*?\*/\s*)*\z}.match?(css)
    end

    def escape_for_js_literal(css)
      css.gsub('\\', '\\\\\\').gsub('`', '\\\`')
    end

    def convertible?(css)
      meta = CssParser.parse_meta(css)
      !(meta['preprocessor']&.any? { |pp| pp != 'default' } || meta['var']&.any?)
    end
  end
end
