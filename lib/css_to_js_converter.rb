require 'css_parser'

class CssToJsConverter
  class << self
    include ActionView::Helpers::JavaScriptHelper

    VERBATIM_META_LINES = %w[name namespace version description author homepageURL supportURL license].freeze
    MATCH_RESULT = Struct.new(:matches, :includes, keyword_init: true)

    def convert(css)
      code_css = CssParser.get_code_blocks(css).join("\n")
      doc_blocks_and_code = CssParser.parse_doc_blocks(code_css)
                                     .map { |doc_block| [doc_block, code_css[doc_block.start_pos..doc_block.end_pos]] }
                                     .reject { |_doc_block, block_code| block_code.blank? }

      # Remove blocks that do nothing - no rules and no code
      if doc_blocks_and_code.many?
        doc_blocks_and_code = doc_blocks_and_code.reject do |doc_block, block_code|
          doc_block.matches.none? && only_comments?(block_code)
        end
      end

      # If we have only one doc block, and the rest is just a @namespace rule, then put the namespace rule inside
      # the doc block.
      if doc_blocks_and_code.many?
        namespace_only_blocks = doc_blocks_and_code.select { |doc_block, block_code| doc_block.matches.none? && only_global_directives?(block_code) }
        if namespace_only_blocks.any?
          namespace_code = "#{namespace_only_blocks.map { |b| b.last.strip }.join("\n")}\n"
          doc_blocks_and_code -= namespace_only_blocks
          doc_blocks_and_code.each do |doc_block_and_code|
            doc_block_and_code[1] = namespace_code + doc_block_and_code[1]
          end
        end
      end

      meta = CssParser.parse_meta(css).slice(*VERBATIM_META_LINES)
      meta['grant'] = ['GM_addStyle']
      meta['run-at'] = ['document-start']

      matches_and_includes = calculate_matches_and_includes(doc_blocks_and_code.map(&:first))
      meta['match'] = matches_and_includes.matches
      meta['include'] = matches_and_includes.includes

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
              "new RegExp(\"#{j css_regexp_to_js(unescape_css(match.value))}\").test(location.href)"
            end
          end
          ["if (#{conditions.join(' || ')}) {", js_for_block.indent(2), '}']
        end
      end
      lines << <<~JS.strip
        if (typeof GM_addStyle !== "undefined") {
          GM_addStyle(css);
        } else {
          const styleNode = document.createElement("style");
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

    def calculate_matches_and_includes(doc_blocks)
      # If there's any without a specific rule, it'll be global.
      return MATCH_RESULT.new(matches: ['*://*/*'], includes: []) if doc_blocks.any? { |doc_block| doc_block.matches.empty? }

      matches = doc_blocks
                .map(&:matches)
                .flatten
                .group_by(&:rule_type)
                .transform_values { |m| m.map(&:value).uniq }

      %w[regexp domain url url-prefix].each { |rule_type| matches[rule_type] = [] unless matches.key?(rule_type) }

      # Regex is not supported by @match rules.
      js_includes = matches['regexp'].map { |re| "/#{css_regexp_to_js(unescape_css(re))}/" }

      js_matches = matches['domain'].map { |domain| "*://*.#{domain}/*" }
      %w[url url-prefix].each do |rule_type|
        # Don't include url or url-prefix if already covered by a domain rule.
        url_and_prefix_rules = matches[rule_type].select do |value|
          uri = URI(value)
        rescue ArgumentError, URI::InvalidURIError
          next true
        else
          next true if uri.host.nil?

          next matches['domain'].exclude?(uri.host)
        end

        if rule_type == 'url-prefix'
          url_and_prefix_rules.each do |value|
            # If there's no slash to indicate where the path starts, we can't tell if they've provided us a full
            # domain, or a domain minus the TLD, or even part of a domain part. Assume that it's a partial domain as
            # that case will work everywhere it should, though it may include some intended domains if what they
            # provided was a full domain (e.g. `url-prefix(https://example.com)` becomes
            # `@include https://example.com*/*` even though that also would include https://example.company.net/. We
            #  use `@include` instead of `@match` because `@match` doesn't support this.
            if value.include?('://') && value.count('/') == 2
              js_includes << "#{value}*/*"
            elsif url_has_port?(value)
              # Match rules don't support URLs with ports.
              js_includes << "#{value}*"
            else
              js_matches << "#{value}*"
            end
          end
        else
          url_and_prefix_rules.each do |value|
            # Match rules don't support URLs with ports.
            if url_has_port?(value)
              js_includes << value
            else
              js_matches << value
            end
          end
        end
      end

      MATCH_RESULT.new(matches: js_matches, includes: js_includes)
    end

    def only_comments?(css)
      css.gsub(%r{/\*.*?\*/}m, '').strip.empty?
    end

    def only_global_directives?(css)
      /\A(\s*@(namespace|charset)[^;]+;\s*)+\z/.match?(css)
    end

    def escape_for_js_literal(css)
      css.gsub('\\', '\\\\\\').gsub('`', '\\\`')
    end

    def unescape_css(css)
      css.gsub('\\\\', '\\')
    end

    def css_regexp_to_js(css_regexp)
      "^(?:#{css_regexp})$"
    end

    def convertible?(css)
      meta = CssParser.parse_meta(css)
      !(meta['preprocessor']&.any? { |pp| pp != 'default' } || meta['var']&.any?)
    end

    def url_has_port?(url)
      uri = URI(url)
      return false unless uri.host

      Regexp.new("//#{Regexp.escape(uri.host)}:[0-9]+(/|\z)").match?(url)
    rescue URI::InvalidURIError
      false
    end
  end
end
