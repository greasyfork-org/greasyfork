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

	def current_url_with_params(p={})
		r = params.except(:only_path, :protocol, :host, :subdomain, :domain, :tld_length, :subdomain, :port, :anchor, :trailing_slash, :script_name, :controller, :action, :format).merge(p)
		r.permit!
		return url_for(r)
	end

	def current_path_with_params(p={})
		return url_for(current_url_with_params(p.merge(only_path: true)))
	end

	def asset_exists?(path)
		if Rails.configuration.assets.compile
			Rails.application.precompiled_assets.include? path
		else
			Rails.application.assets_manifest.assets[path].present?
		end
	end

	def asset_path_if_exists(path)
		return asset_path(path) if asset_exists?(path)
	end

	TOP_SCRIPTS_PERCENTAGE = 0.2
	TOP_SCRIPTS_COUNT = 5

	# Sample from the top scripts.
	def highlighted_script_ids_for_locale(locale:, script_subset:, restrict_to_ad_method: nil)
		highlightable_scripts = Script.listable(script_subset)
		highlightable_scripts = highlightable_scripts.where(ad_method: restrict_to_ad_method) if restrict_to_ad_method

		# Use scripts in the passed locale first.
		locale_scripts = highlightable_scripts.joins(:localized_attributes => :locale).references([:localized_attributes, :locale]).where('localized_script_attributes.attribute_key' => 'name').where('locales.code' => I18n.locale)
		locale_scripts = locale_scripts.select(:id)
		locale_script_count = locale_scripts.count
		top_percentage_count = (locale_script_count * TOP_SCRIPTS_PERCENTAGE).to_i
		# If there are enough from the top percentage, then sample from that.
		if top_percentage_count >= TOP_SCRIPTS_COUNT
			highlighted_scripts = Set.new + locale_scripts.order('daily_installs DESC').limit(top_percentage_count).sample(TOP_SCRIPTS_COUNT).map{|s| s.id}
		else
			# Otherwise, sample from all scripts in this locale.
			highlighted_scripts = Set.new + locale_scripts.sample(TOP_SCRIPTS_COUNT).map{|s| s.id}
		end

		# If we don't have enough, use scripts that aren't in the passed locale.
		if highlighted_scripts.length < TOP_SCRIPTS_COUNT
			total_script_count = highlightable_scripts.count
			highlightable_scripts.order('daily_installs DESC').limit((total_script_count * TOP_SCRIPTS_PERCENTAGE).to_i).select(:id).map{|s| s.id}.shuffle.each do |id|
				highlighted_scripts << id
				break if highlighted_scripts.length >= TOP_SCRIPTS_COUNT
			end
		end

		return highlighted_scripts.to_a.shuffle
	end

	def highlighted_scripts(restrict_to_ad_method: nil)
		highlighted_scripts_ids = cache_with_log("scripts/highlighted/#{script_subset}/#{I18n.locale.to_s}/#{restrict_to_ad_method}") do
			highlighted_script_ids_for_locale(locale: I18n.locale, script_subset: script_subset, restrict_to_ad_method: restrict_to_ad_method)
		end
		@highlighted_scripts = Script.includes(:localized_attributes => :locale).find(highlighted_scripts_ids.to_a)
	end
end
