require 'sanitize'

module ApplicationHelper

	def format_user_text(text)
		return '' if text.nil?
		yes_follow = lambda do |env|
			follow_domains = ['mozillazine.org', 'mozilla.org', 'mozilla.com', 'userscripts.org', 'userstyles.org', 'mozdev.org', 'photobucket.com', 'facebook.com', 'chrome.google.com', 'github.com', 'greasyfork.org']
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
			return if has_anchor_ancestor(node)
			url_reference = node.text.match(/(\s|^|\()(https?:\/\/[^\s\)\]]*)/i)
			return if url_reference.nil?
			resulting_nodes = replace_text_with_link(node, url_reference[2], url_reference[2], url_reference[2])
			# sanitize the new nodes ourselves; they won't be picked up otherwise.
			resulting_nodes.delete(node)
			resulting_nodes.each do |new_node|

				Sanitize.clean_node!(new_node, env[:config])
			end
		end

		fix_whitespace = lambda do |env|
			node = env[:node]
			return unless node.text?
			node.content = node.content.lstrip if node.previous_sibling.nil? or (!node.previous_sibling.description.nil? and node.previous_sibling.description.block?)
			node.content = node.content.rstrip if node.next_sibling.nil? or (!node.next_sibling.description.nil? and node.next_sibling.description.block?)
			return if node.text.empty?
			return unless node.text.include?("\n")
			resulting_nodes = replace_text_with_node(node, "\n", Nokogiri::XML::Node.new('br', node.document))
			# sanitize the new nodes ourselves; they won't be picked up otherwise.
			resulting_nodes.delete(node)
			resulting_nodes.each do |new_node|
				Sanitize.clean_node!(new_node, env[:config])
			end
		end

		config = Sanitize::Config::BASIC.merge({
			:transformers => [linkify_urls, yes_follow, fix_whitespace]
		})
		Sanitize.clean(text, config).html_safe
	end

private

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

	def has_anchor_ancestor(node)
		until node.nil?
			return true if node.name == 'a'
			node = node.parent
		end
		return false
	end



end
