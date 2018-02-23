require 'memoist'

module ScriptsHelper
	extend Memoist

	def script_list_link(label, sort: nil, site: nil, set: nil, default_sort: nil)
		is_link = true
		is_minified = action_name == 'minified'
		is_code_search = action_name == 'code_search'
		is_libraries = action_name == 'libraries'
		# sets can have a different default
		sort_param_to_use = (sort == default_sort) ? nil : sort
		if sort == params[:sort] && site == params[:site] && set == params[:set]
			l = label
			is_link = false
		elsif is_libraries
			l = link_to label, libraries_scripts_path(:sort => sort_param_to_use, :q => params[:q], :set => set)
		elsif is_minified
			l = link_to label, minified_scripts_path(:sort => sort_param_to_use)
		elsif is_code_search
			l = link_to label, code_search_scripts_path(:sort => sort_param_to_use, :c => params[:c])
		elsif site.nil?
			l = link_to label, {:sort => sort_param_to_use, :site => nil, :set => set, :q => params[:q]}
		elsif params[:controller] == 'users'
			l = link_to label, {:sort => sort_param_to_use, :site => site, :set => set}
		else
			l = link_to label, by_site_scripts_path(:sort => sort_param_to_use, :site => site, :set => set, :q => params[:q])
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

	def license_display(script)
		return link_to(script.license.code, script.license.url, title: script.license.name) if script.license&.url
		return script.license.code if script.license
		return "<i>#{I18n.t('scripts.no_license')}</i>".html_safe if script.license_text.nil?
		return script.license_text
	end

	def promoted_script
		return nil if sleazy?
		return nil if @script&.sensitive
		return nil if current_user && !current_user.show_ads
		return @script.promoted_script if @script&.promoted_script
		return nil unless Random.rand(Rails.application.config.promoted_script_divisor) == 0
		return Script.where(promoted: true).sample
	end
	memoize :promoted_script

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
