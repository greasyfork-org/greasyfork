module ScriptsHelper

	def script_list_link(label, sort = nil, site = nil)
		is_link = true
		if sort == params[:sort] and site == params[:site]
			l = label
			is_link = false
		elsif site.nil?
			l = link_to label, scripts_path(:sort => sort)
		else
			l = link_to label, by_site_scripts_path(:sort => sort, :site => site)
		end
		return ("<span class=\"script-list-option#{is_link ? '' : ' script-list-current'}\">" + l + '</span>').html_safe
	end

end
