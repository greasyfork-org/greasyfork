module ScriptsHelper

	def script_list_link(label, sort = nil, site = nil, set = nil, current_set = nil)
		is_link = true
		is_search = action_name == 'search'
		is_minified = action_name == 'minified'
		is_code_search = action_name == 'code_search'
		# sets can have a different default
		sort_param_to_use = (!current_set.nil? && sort == current_set.default_sort) ? nil : sort
		# if everything in the current page is the same as what we would link too, don't link!
		if sort_param_to_use == params[:sort] and (is_search or site == params[:site]) and ((set.nil? and params[:set].nil?) or set.to_s == params[:set])
			l = label
			is_link = false
		elsif is_search
			l = link_to label, search_scripts_path(:sort => sort_param_to_use, :q => params[:q], :set => set)
		elsif is_minified
			l = link_to label, minified_scripts_path(:sort => sort_param_to_use)
		elsif is_code_search
			l = link_to label, code_search_scripts_path(:sort => sort_param_to_use, :c => params[:c])
		elsif site.nil?
			l = link_to label, {:sort => sort_param_to_use, :set => set, :site => nil}
		elsif params[:controller] == 'users'
			l = link_to label, {:sort => sort_param_to_use, :site => site, :set => set}
		else
			l = link_to label, by_site_scripts_path(:sort => sort_param_to_use, :site => site, :set => set)
		end
		return ("<li class=\"list-option#{is_link ? '' : ' list-current'}\">" + l + '</li>').html_safe
	end

	def script_applies_to_list_contents(script, by_sites)
		sats_with_domains, sats_without_domains = script.script_applies_tos.partition{|sat|sat.domain}
		return (
		sats_with_domains.map{ |sat|			
			content_for_script_applies_to_that_has_domain(sat, count_of_other_scripts_with_sat(sat, script, by_sites))
		} +
		sats_without_domains.map{ |sat| content_tag(:code, sat.text) }
		)
	end

private

	def content_for_script_applies_to_that_has_domain(sat, count_of_other_scripts)
		if count_of_other_scripts > 0
			title = t('scripts.applies_to_link_title', {:count => count_of_other_scripts, :site => sat.text})
			return link_to(sat.text, by_site_scripts_path(:site => sat.text), {:title => title})
		end
		return sat.text
	end

	def count_of_other_scripts_with_sat(script_applies_to, script, by_sites)
		return 0 if by_sites[script_applies_to.text].nil?
		# take this one out of the count if it's a listable
		return (by_sites[script_applies_to.text][:scripts] - (script.listable? ? 1 : 0))
	end

end
