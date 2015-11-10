require 'sanitize'
require 'redcarpet'

module ApplicationHelper

	def title(page_title)
		content_for(:title) { page_title }
	end

	def description(page_description)
		content_for(:description) { page_description }
	end

	# Per-request cache
	def relative_time_cutoff
		@relative_time_cutoff ||= 1.week.ago
	end

	def markup_date(date)
		return '?' if date.nil?
		# Take out "about" and "less than" to make it shorter. Obviously won't work in the other languages.
		"<time datetime=\"#{date.to_datetime.rfc3339}\">#{date > relative_time_cutoff ? relative_time(date) : date.strftime('%Y-%m-%d')}</time>".html_safe
	end

	def relative_time(date)
		diff_in_minutes = ((Time.now - date) / 60.0).round
		return I18n.translate('helpers.application.time_ago.minutes', count: diff_in_minutes) if diff_in_minutes < 60
		return I18n.translate('helpers.application.time_ago.hours', count: (diff_in_minutes / 60.0).round) if diff_in_minutes < 1440
		return I18n.translate('helpers.application.time_ago.days', count: (diff_in_minutes / 1440.0).round)
	end

	def format_user_text(text, markup_type)
		return '' if text.nil?
		return format_user_text_html(text) if markup_type == 'html'
		return format_user_text_markdown(text) if markup_type == 'markdown'
		return ''
	end

	# Returns the plain text representation of the passed markup
	def format_user_text_as_plain(text, markup_type)
		Sanitize.clean(format_user_text(text, markup_type))
	end

	def format_user_text_html(text)
		Sanitize.clean(text, get_html_sanitize_config).html_safe
	end

	def format_user_text_markdown(text)
		Sanitize.clean(@@markdown.render(text), get_markdown_sanitize_config).html_safe
	end

	def discussion_class(discussion)
		case discussion.Rating
			when 0
				return 'discussion-question'
			when 1
				return 'discussion-report'
			when 2
				return 'discussion-bad'
			when 3
				return 'discussion-ok'
			when 4
				return 'discussion-good'
		end
	end

	def get_html_sanitize_config
		if @@html_sanitize_config.nil?
			@@html_sanitize_config = get_markdown_sanitize_config.dup
			fix_whitespace = lambda do |env|
				node = env[:node]
				return unless node.text?
				return if has_ancestor(node, 'pre')
				node.content = node.content.lstrip if element_is_block(node.previous_sibling)
				node.content = node.content.rstrip if element_is_block(node.next_sibling)
				return if node.text.empty?
				return unless node.text.include?("\n")
				resulting_nodes = replace_text_with_node(node, "\n", Nokogiri::XML::Node.new('br', node.document))
			end

			@@html_sanitize_config[:transformers] << fix_whitespace
		end
		return @@html_sanitize_config
	end

	def get_markdown_sanitize_config
		if @@markdown_sanitize_config.nil?
			@@markdown_sanitize_config = Sanitize::Config::BASIC.dup
			@@markdown_sanitize_config[:elements] = @@markdown_sanitize_config[:elements].dup
			@@markdown_sanitize_config[:elements].concat(['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'img', 'hr', 'del', 'ins', 'table', 'tr', 'th', 'td', 'thead', 'tbody', 'tfoot', 'span', 'div', 'tt', 'center', 'ruby', 'rt', 'rp'])
			@@markdown_sanitize_config[:attributes] = @@markdown_sanitize_config[:attributes].merge('img' => ['src', 'alt', 'height', 'width'], :all => ['title', 'name'])
			@@markdown_sanitize_config[:protocols] = @@markdown_sanitize_config[:protocols].merge('img' => {'src'  => ['https']})
			@@markdown_sanitize_config[:remove_contents] = ['script', 'style']

			yes_follow = lambda do |env|
				follow_domains = ['mozillazine.org', 'mozilla.org', 'mozilla.com', 'userscripts.org', 'userstyles.org', 'mozdev.org', 'photobucket.com', 'facebook.com', 'chrome.google.com', 'github.com', 'greasyfork.org', 'openuserjs.org']
				return unless env[:node_name] == 'a'
				node = env[:node]
				href = nil
				href = node['href'].downcase unless node['href'].nil?
				follow = false
				if href.nil?
					# missing the href, we don't want a rel here
					follow = true
				elsif href =~ Sanitize::REGEX_PROTOCOL
					# external link, let's figure out the domain if it's http or https
					match = /https?:\/\/([^\/]+).*/.match(href)
					# check domain against our list, including subdomains
					if !match.nil?
						follow_domains.each do |d|
							if match[1] == d or match[1].ends_with?('.' + d)
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

				# whitelist so the initial clean call doesn't strip the rel
				return {:node_whitelist => [node]}
			end
			linkify_urls = lambda do |env|
				node = env[:node]
				return unless node.text?
				return if has_ancestor(node, 'a')
				return if has_ancestor(node, 'pre')
				url_reference = node.text.match(/(\s|^|\()(https?:\/\/[^\s\)\]]*)/i)
				return if url_reference.nil?
				resulting_nodes = replace_text_with_link(node, url_reference[2], url_reference[2], url_reference[2])
			end

			@@markdown_sanitize_config[:transformers] = [linkify_urls, yes_follow]
		end
		return @@markdown_sanitize_config
	end

	def self_link(name, text)
		"<span id=\"#{name}\">#{link_to('§', {:anchor => name}, {:class => 'self-link'})} #{text}</span>".html_safe
	end


	def forum_path
		return "/#{I18n.locale}/forum/"
	end

	# Translates an array of keys and returns a hash.
	def translate_keys(keys)
		h = {}
		keys.each{|k| h[k] = I18n.t(k)}
		return h
	end

	def social_share_locale
		return I18n.locale.to_s if ['de', 'es', 'fr', 'it', 'nl', 'pl', 'pt', 'ru'].include?(I18n.locale.to_s)
		return 'pt' if I18n.locale.to_s == 'pt-BR'
		return 'fr' if I18n.locale.to_s == 'fr-CA'
		return nil
	end

private

	@@markdown_sanitize_config = nil
	@@html_sanitize_config = nil

	def replace_text_with_link(node, original_text, link_text, url)
			# the text itself becomes a link
			link = Nokogiri::XML::Node.new('a', node.document)
			link['href'] = url
			link.add_child(Nokogiri::XML::Text.new(link_text, node.document))
			return replace_text_with_node(node, original_text, link)
	end

	def replace_text_with_node(node, text, node_to_insert)
			original_content = node.text
			start = node.text.index(text)
			# the stuff before stays in the current node
			node.content = original_content[0, start]
			# add the new node
			node.add_next_sibling(node_to_insert)
			# the stuff after becomes a new text node
			node_to_insert.add_next_sibling(Nokogiri::XML::Text.new(original_content[start + text.size, original_content.size], node.document))
			return [node, node.next_sibling, node.next_sibling.next_sibling]
	end

	def has_ancestor(node, ancestor_node_name)
		until node.nil?
			return true if node.name == ancestor_node_name
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

	@@markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new({:link_attributes => {:rel => 'nofollow'}}), :fenced_code_blocks => true, :lax_spacing => true)

end
