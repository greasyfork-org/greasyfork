module ScriptsHelper

	def script_list_link(label, sort = nil, site = nil)
		is_link = true
		is_search = action_name == 'search'
		if sort == params[:sort] and (is_search or site == params[:site])
			l = label
			is_link = false
		elsif is_search
			l = link_to label, search_scripts_path(:sort => sort, :q => params[:q])
		elsif site.nil?
			l = link_to label, scripts_path(:sort => sort)
		else
			l = link_to label, by_site_scripts_path(:sort => sort, :site => site)
		end
		return ("<span class=\"script-list-option#{is_link ? '' : ' script-list-current'}\">" + l + '</span>').html_safe
	end

end
