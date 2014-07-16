atom_feed(:root_url => url_for(params.except(:format).merge(:host => request.host))) do |feed|
	feed.title(@title)
	feed.subtitle(@description)
	feed.updated(@scripts[0].code_updated_at) if @scripts.length > 0

	@scripts.each do |script|
		feed.entry(script, :updated => script.code_updated_at) do |entry|
			entry.title(script.name)
			entry.content("<p>#{h(script.description)}</p>".html_safe + format_user_text(script.additional_info, script.additional_info_markup), type: 'html')
			if script.license.nil?
				if !script.license_text.nil?
					entry.rights(script.license_text, type: 'text')
				end
			else
				entry.rights(script.license.html.html_safe, type: 'html')
			end

			entry.author do |author|
				author.name(script.user.name)
				author.uri(user_path(script.user, :only_path => false))
			end
		end
	end
end
