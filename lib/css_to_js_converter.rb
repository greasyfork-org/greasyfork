require 'css_parser'

class CssToJsConverter
  class << self
    include ActionView::Helpers::JavaScriptHelper

    VERBATIM_META_LINES = %w(name version namespace description author homepageURL supportURL license)

    def convert(css)
      code_css = CssParser.get_code_blocks(css).join("\n")
      doc_blocks_and_code = CssParser.parse_doc_blocks(code_css, calculate_block_positions: true)
                             .map{ |doc_block| [doc_block, code_css[doc_block.start_pos..doc_block.end_pos]] }
                             .reject{ |doc_block, block_code| block_code.blank? }

      meta = CssParser.parse_meta(css).select{|k, v| VERBATIM_META_LINES.include?(k) }
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
        lines << "let css = `#{doc_blocks_and_code.first.last.gsub('`', '\`')}`;"
      else
        lines << 'let css = "";'
        lines += doc_blocks_and_code.map do |doc_block, block_code|
          js_for_block = "css += `#{block_code.gsub('`', '\`')}`;"
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
          ["if (#{conditions.join(' || ')}) {", js_for_block.indent(2), "}"]
        end
      end
      lines << <<~JS.strip
        if (typeof GM_addStyle !== "undefined") {
          GM_addStyle(css);
        } else {
          var styleNode = document.createElement("style");
          node.appendChild(document.createTextNode(css));
          (document.querySelector("head") || document.documentElement).appendChild(node);
        }
      JS
      lines << '})();'
      lines.flatten.join("\n") + "\n"
    end

    def j(c)
      escape_javascript(c)
    end

    def calculate_includes(doc_blocks)
      # If there's any without a specific rule, it'll be global.
      return ['*'] if doc_blocks.any?{ |doc_block| doc_block.matches.empty? }

      matches = doc_blocks
                    .map(&:matches)
                    .flatten
                    .group_by(&:rule_type)
                    .map { |rule_type, m| [rule_type, m.map(&:value).uniq] }
                    .to_h

      %w(regexp domain url url-prefix).each { |rule_type| matches[rule_type] = [] unless matches.has_key?(rule_type) }

      js_includes = matches['regexp'].map { |re| "/#{re}/" }
      js_includes += matches['domain'].map { |domain| [domain, "*.#{domain}"].map { |d| ["http://#{d}/*", "https://#{d}/*"] } }.flatten

      # Don't include url or url-prefix if already covered by a domain rule.
      %w(url url-prefix).each do |rule_type|
        js_includes += matches[rule_type].select do |value|
          begin
            uri = URI(value)
          rescue ArgumentError, URI::InvalidURIError
            next true
          else
            next true if uri.host.nil?
            next !matches['domain'].include?(uri.host)
          end
        end.map{ |value| value + (rule_type == 'url-prefix' ? '*' : '')}
      end

      js_includes.uniq
    end
  end
end