module ScriptsHelper

	def script_list_link(label, sort = nil, site = nil, set = nil)
		is_link = true
		is_search = action_name == 'search'
		is_minified = action_name == 'minified'
		is_code_search = action_name == 'code_search'
		if sort == params[:sort] and (is_search or site == params[:site]) and ((set.nil? and params[:set].nil?) or set.to_s == params[:set])
			l = label
			is_link = false
		elsif is_search
			l = link_to label, search_scripts_path(:sort => sort, :q => params[:q], :set => set)
		elsif is_minified
			l = link_to label, minified_scripts_path(:sort => sort)
		elsif is_code_search
			l = link_to label, code_search_scripts_path(:sort => sort, :c => params[:c])
		elsif site.nil?
			l = link_to label, scripts_path(:sort => sort, :set => set)
		else
			l = link_to label, by_site_scripts_path(:sort => sort, :site => site, :set => set)
		end
		return ("<li class=\"script-list-option#{is_link ? '' : ' script-list-current'}\">" + l + '</li>').html_safe
	end

end
