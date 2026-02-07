require 'sanitize'
require 'redcarpet'
require 'memo_wise'

module UserTextHelper
  prepend MemoWise

  def with_user_text_preview(markup_name:, markup:, &)
    markup_choice_html = label_tag(nil, class: 'radio-label') do
      "#{radio_button_tag(markup_name, 'html', markup == 'html' || markup.nil?, required: true)}HTML".html_safe
    end +
                         label_tag(nil, class: 'radio-label') do
                           radio_button_tag(markup_name, 'markdown', markup == 'markdown', required: true) +
                             link_to('Markdown', 'http://daringfireball.net/projects/markdown/basics', { target: 'markup_choice' })
                         end
    previewable_text_field_form(markup_name:, markup_choice_html:, &)
  end

  def with_user_text_preview_for_form(form:, markup_name:, &)
    markup_choice_html = label_tag(nil, class: 'radio-label') do
      "#{form.radio_button(markup_name, 'html', required: true)}HTML".html_safe
    end +
                         label_tag(nil, class: 'radio-label') do
                           form.radio_button(markup_name, 'markdown', required: true) +
                             link_to('Markdown', 'http://daringfireball.net/projects/markdown/basics', { target: 'markup_choice' })
                         end
    previewable_text_field_form(markup_name: "#{form.object_name}[#{markup_name}]", markup_choice_html:, &)
  end

  def format_user_text(text, markup_type, mentions: [], relative_url_base: nil)
    return '' if text.nil?
    return text if markup_type == 'text'

    sanitize_config = sanitize_config_for_display(markup_type, mentions:)

    if markup_type == 'markdown'
      text = markdown.render(text)
      # This is done on import for HTML, but here for Markdown. This is because we don't have a function to adjust
      # Markdown.
      text = ScriptImporter::BaseScriptImporter.absolutize_references(text, relative_url_base) if relative_url_base
    end

    Sanitize.clean(text, sanitize_config).html_safe
  end

  # Same as sanitize's default, but line breaks rather than spaces.
  USE_LINE_BREAK_OPTIONS = {
    whitespace_elements: {
      'address' => { before: "\n", after: "\n" },
      'article' => { before: "\n", after: "\n" },
      'aside' => { before: "\n", after: "\n" },
      'blockquote' => { before: "\n", after: "\n" },
      'br' => { before: "\n", after: "\n" },
      'dd' => { before: "\n", after: "\n" },
      'div' => { before: "\n", after: "\n" },
      'dl' => { before: "\n", after: "\n" },
      'dt' => { before: "\n", after: "\n" },
      'footer' => { before: "\n", after: "\n" },
      'h1' => { before: "\n", after: "\n" },
      'h2' => { before: "\n", after: "\n" },
      'h3' => { before: "\n", after: "\n" },
      'h4' => { before: "\n", after: "\n" },
      'h5' => { before: "\n", after: "\n" },
      'h6' => { before: "\n", after: "\n" },
      'header' => { before: "\n", after: "\n" },
      'hgroup' => { before: "\n", after: "\n" },
      'hr' => { before: "\n", after: "\n" },
      'li' => { before: "\n", after: "\n" },
      'nav' => { before: "\n", after: "\n" },
      'ol' => { before: "\n", after: "\n" },
      'p' => { before: "\n", after: "\n" },
      'pre' => { before: "\n", after: "\n" },
      'section' => { before: "\n", after: "\n" },
      'ul' => { before: "\n", after: "\n" },
    },
  }.freeze

  # Returns the plain text representation of the passed markup
  def format_user_text_as_plain(text, markup_type, use_line_breaks: false)
    Sanitize.fragment(format_user_text(text, markup_type), use_line_breaks ? USE_LINE_BREAK_OPTIONS : {}).strip
  end

  # Returns an inline-only representation of the passed markup.
  def format_user_text_as_inline(text, markup_type)
    Sanitize.fragment(format_user_text(text, markup_type), Sanitize::Config::RESTRICTED)
  end

  def detect_possible_mentions(text, markup_type)
    return [] unless %w[html markdown].include?(markup_type)
    return [] if text.blank?

    mentions = Set.new
    sanitize_config = (markup_type == 'html') ? html_sanitize_config : markdown_sanitize_config
    add_detect_mention_transformer(sanitize_config, mentions)

    text = markdown.render(text) if markup_type == 'markdown'
    Sanitize.clean(text, sanitize_config).html_safe

    mentions
  end

  MENTIONLESS_ELEMENTS = %w[a pre code].freeze

  private

  def add_mention_transformer(config, mentions)
    linkify_mentions = lambda do |env|
      node = env[:node]
      return unless node.text?
      return if node_has_ancestor?(node, MENTIONLESS_ELEMENTS)

      # We can't #select the used mentions as node.text will change when we do the replacements.
      mentions.each do |mention|
        next unless node.text.include?(mention.text)

        # Link text should not include beginning/trailing quotes.
        link_text = mention.text
        link_text_match = /\A@"(.*)"\z/.match(link_text)
        link_text = "@#{link_text_match[1]}" if link_text_match

        replace_text_with_link(node, mention.text, link_text, user_path(mention.user, locale: request_locale.code))
      end
    end

    config[:transformers] += [linkify_mentions]
  end

  def add_detect_mention_transformer(config, mentions_out)
    detect_user_references = lambda do |env|
      node = env[:node]
      return unless node.text?
      return if node_has_ancestor?(node, MENTIONLESS_ELEMENTS)

      mentions_out.merge(node.text.scan(/(?<=\s|^)(@[^\s"][^\s]{0,49})(?=\s|$)/).flatten.compact)
      mentions_out.merge(node.text.scan(/(?<=\s|^)(@"[^"]{1,50}")/).flatten.compact)
    end

    config[:transformers] << detect_user_references
  end

  def html_sanitize_config
    hsc = markdown_sanitize_config.dup
    fix_whitespace = lambda do |env|
      node = env[:node]
      return unless node.text?
      return if node_has_ancestor?(node, 'pre')

      node.content = node.content.lstrip if element_is_block(node.previous_sibling)
      node.content = node.content.rstrip if element_is_block(node.next_sibling)
      return if node.text.empty?
      return unless node.text.include?("\n")

      replace_text_with_node(node, "\n", Nokogiri::XML::Node.new('br', node.document))
    end

    ensure_block_level = lambda do |env|
      node = env[:node]

      # Looking for top-level text or non-block elements.
      return unless node.text? || (node.element? & !element_is_block(node))
      return unless node.parent.fragment?

      paragraph = Nokogiri::XML::Node.new('p', node.document)
      node.before(paragraph)
      next_node = node
      while next_node && (next_node.text? || (next_node.element? & !element_is_block(next_node)))
        # Need to store this before add_child, as that will move it
        next_sibling = next_node.next_sibling
        paragraph.add_child(next_node)
        next_node = next_sibling
      end
    end

    hsc[:transformers] += [fix_whitespace, ensure_block_level]

    hsc
  end

  def markdown_sanitize_config
    msc = Sanitize::Config::BASIC.dup
    msc[:elements] = msc[:elements].dup
    msc[:elements].push('h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'img', 'hr', 'del', 'ins', 'table', 'tr', 'th', 'td', 'thead', 'tbody', 'tfoot', 'span', 'div', 'tt', 'center', 'ruby', 'rt', 'rp', 'video', 'details', 'summary')
    msc[:attributes] = msc[:attributes].merge('img' => %w[src alt height width], 'video' => %w[src poster height width], 'details' => ['open'], :all => %w[title name style])
    msc[:css] = { properties: %w[border background-color color] }
    msc[:protocols] = msc[:protocols].merge('img' => { 'src' => ['https'] }, 'video' => { 'src' => ['https'] })
    msc[:remove_contents] = %w[script style]
    msc[:add_attributes] = msc[:add_attributes].merge('video' => { 'controls' => 'controls' })

    yes_follow = lambda do |env|
      follow_domains = ['mozillazine.org', 'mozilla.org', 'mozilla.com', 'mozdev.org', 'photobucket.com', 'facebook.com', 'chrome.google.com', 'github.com', 'greasyfork.org', 'openuserjs.org']
      return unless env[:node_name] == 'a'

      node = env[:node]
      href = nil
      href = node['href'].downcase unless node['href'].nil?
      follow = false
      if href.nil?
        # missing the href, we don't want a rel here
        follow = true
      elsif Sanitize::REGEX_PROTOCOL.match?(href)
        # external link, let's figure out the domain if it's http or https
        match = %r{https?://([^/]+).*}.match(href)
        # check domain against our list, including subdomains
        unless match.nil?
          follow_domains.each do |d|
            if (match[1] == d) || match[1].ends_with?(".#{d}")
              follow = true
              break
            end
          end
        end
      else
        # internal link
        follow = true
      end
      if follow
        # take out any rel value the user may have provided
        node.delete('rel')
      else
        node['rel'] = 'nofollow'
      end

      # make a config that allows the rel attribute and does not include this transformer
      # do a deep copy of anything we're going to change
      config_allows_rel = env[:config].dup
      config_allows_rel[:attributes] = config_allows_rel[:attributes].dup
      config_allows_rel[:attributes]['a'] = config_allows_rel[:attributes]['a'].dup
      config_allows_rel[:attributes]['a'] << 'rel'
      config_allows_rel[:add_attributes] = config_allows_rel[:add_attributes].dup
      config_allows_rel[:add_attributes]['a'] = config_allows_rel[:add_attributes]['a'].dup
      config_allows_rel[:add_attributes]['a'].delete('rel')
      config_allows_rel[:transformers] = config_allows_rel[:transformers].dup
      config_allows_rel[:transformers].delete(yes_follow)

      Sanitize.clean_node!(node, config_allows_rel)

      # allow so the initial clean call doesn't strip the rel
      return { node_allowlist: [node] }
    end

    linkify_urls = lambda do |env|
      node = env[:node]
      return unless node.text?
      return if node_has_ancestor?(node, 'a')
      return if node_has_ancestor?(node, 'pre')

      url_reference = node.text.match(%r{(\s|^|\()(https?://[^\s)\]]+)}i)
      return if url_reference.nil?

      url_reference = url_reference[2]
      url_reference.gsub!(/[.,?!]+\z/u, '')

      replace_text_with_link(node, url_reference, url_reference, url_reference)
    end

    youtube_transformer = lambda do |env|
      node      = env[:node]
      node_name = env[:node_name]

      # Don't continue if this node is already allowlisted or is not an element.
      return if env[:is_allowlisted] || !node.element?

      # Don't continue unless the node is an iframe.
      return unless node_name == 'iframe'

      # Verify that the video URL is actually a valid YouTube video URL.
      return unless %r{\A(?:https:)?//(?:www\.)?youtube(?:-nocookie)?\.com/}.match?(node['src']) || %r{\A(?:https:)?//player\.bilibili\.com/player\.html}.match?(node['src'])

      # We're now certain that this is a YouTube embed, but we still need to run
      # it through a special Sanitize step to ensure that no unwanted elements or
      # attributes that don't belong in a YouTube embed can sneak in.
      Sanitize.node!(node, {
                       elements: %w[iframe],

                       attributes: {
                         'iframe' => %w[allowfullscreen frameborder height src width],
                       },
                     })

      # Now that we're sure that this is a valid YouTube embed and that there are
      # no unwanted elements or attributes hidden inside it, we can tell Sanitize
      # to allowlist the current node.
      { node_allowlist: [node] }
    end

    msc[:transformers] = [linkify_urls, yes_follow, youtube_transformer]

    msc
  end

  def replace_text_with_link(node, original_text, link_text, url)
    # the text itself becomes a link
    link = Nokogiri::XML::Node.new('a', node.document)
    link['href'] = url
    link.add_child(Nokogiri::XML::Text.new(link_text, node.document))
    replace_text_with_node(node, original_text, link, once: true)
  end

  def replace_text_with_node(node, text, node_to_insert, once: false)
    node_text = node.text
    replaced_original_node = false

    # Can't use split because we'd swallow consecutive delimiters.

    # Put everything in a fragment first and insert it all at once for performance.
    fragment = Nokogiri::HTML::DocumentFragment.new(node.document)
    while node_text
      index = node_text.index(text)
      if index.nil?
        fragment << Nokogiri::XML::Text.new(node_text, node.document)
        break
      end
      if replaced_original_node
        fragment << Nokogiri::XML::Text.new(node_text[0, index], node.document)
      else
        node.content = node_text[0, index]
        replaced_original_node = true
      end
      fragment << node_to_insert.dup
      node_text = node_text[(index + text.length)..]

      if once
        fragment << Nokogiri::XML::Text.new(node_text, node.document)
        break
      end
    end

    node.add_next_sibling(fragment)
  end

  def node_has_ancestor?(node, ancestor_node_names)
    ancestor_node_names = Array(ancestor_node_names)
    until node.nil?
      return true if ancestor_node_names.include?(node.name)

      node = node.parent
    end
    return false
  end

  def element_is_block(node)
    return false if node.nil?

    # https://github.com/rgrove/sanitize/issues/108
    d = Nokogiri::HTML::ElementDescription[node.name]
    return !d.nil? && d.block?
  end

  def markdown
    @markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML.new({ link_attributes: { rel: 'nofollow' } }), fenced_code_blocks: true, lax_spacing: true, tables: true, strikethrough: true, no_intra_emphasis: true)
  end

  def previewable_text_field_form(markup_name:, markup_choice_html:)
    <<~HTML.html_safe
      <span class="label-note markup-options">
        #{link_to t('common.allowed_elements_link'), help_allowed_markup_path, { target: 'markup_choice' }}
        #{markup_choice_html}
      </span><br>
      <div class="previewable" data-markup-option-name="#{markup_name}" data-preview-label="#{t('common.preview_tab')}" data-write-label="#{t('common.write_tab')}">
        #{yield}
      </div>
    HTML
  end

  module_function

  def sanitize_config_for_display(markup_type, mentions: [])
    config = case markup_type
             when 'html'
               html_sanitize_config
             when 'markdown'
               markdown_sanitize_config
             else
               raise "Unknown markup_type #{markup_type}."
             end

    # Create a closure around the mentions transformer including the actual mentions, as there's no other way to get that data
    # inside sanitize's transformer system. If there are no mentions, avoid doing this, as the transformer will be a no-op, and
    # we can avoid the #dup.
    if mentions.any?
      config = config.dup
      add_mention_transformer(config, mentions)
    end

    config
  end
  memo_wise self: :sanitize_config_for_display
end
