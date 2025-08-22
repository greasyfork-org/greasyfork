require 'will_paginate/action_view/link_renderer_with_no_follow'

module ApplicationHelper
  def title(page_title)
    content_for(:title) { page_title }
  end

  def description(page_description)
    content_for(:description) { page_description }
  end

  def markup_date(date, **)
    return '?' if date.nil?

    tag.relative_time(datetime: date.to_datetime.rfc3339, **, prefix: '') { I18n.l(date.to_date) }
  end

  def self_link(name, text)
    tag.span(id: name) { link_to('§', { anchor: name }, { class: 'self-link' }) + text }
  end

  # Translates an array of keys and returns a hash.
  def translate_keys(keys)
    h = {}
    keys.each { |k| h[k] = I18n.t(k) }
    return h
  end

  def safe_params(other_params = {})
    r = params.except(:only_path, :protocol, :host, :subdomain, :domain, :tld_length, :subdomain, :port, :anchor, :trailing_slash, :script_name, :controller, :action, :format).merge(other_params)
    r.permit!
    r
  end

  def current_url_with_params(other_params = {})
    return url_for(safe_params(other_params))
  end

  def current_api_url_with_params(other_params = {})
    return url_for(**safe_params(other_params), subdomain: 'api')
  end

  def current_path_with_params(other_params = {})
    return url_for(current_url_with_params(other_params.merge(only_path: true)))
  end

  TOP_SCRIPTS_PERCENTAGE = 0.2
  TOP_SCRIPTS_COUNT = 5

  # Sample from the top scripts.
  def highlighted_script_ids_for_locale(locale:, script_subset:, restrict_to_ad_method: nil)
    highlightable_scripts = Script.listable(script_subset)
    highlightable_scripts = highlightable_scripts.where(adsense_approved: true) if restrict_to_ad_method

    # Use scripts in the passed locale first.
    locale_scripts = highlightable_scripts.joins(localized_attributes: :locale).references([:localized_attributes, :locale]).where('localized_script_attributes.attribute_key' => 'name').where('locales.code' => locale)
    locale_scripts = locale_scripts.select(:id)
    locale_script_count = locale_scripts.count
    top_percentage_count = (locale_script_count * TOP_SCRIPTS_PERCENTAGE).to_i
    # If there are enough from the top percentage, then sample from that.
    highlighted_scripts = if top_percentage_count >= TOP_SCRIPTS_COUNT
                            Set.new + locale_scripts.order(daily_installs: :desc).limit(top_percentage_count).sample(TOP_SCRIPTS_COUNT).map(&:id)
                          else
                            # Otherwise, sample from all scripts in this locale.
                            Set.new + locale_scripts.sample(TOP_SCRIPTS_COUNT).map(&:id)
                          end

    # If we don't have enough, use scripts that aren't in the passed locale.
    if highlighted_scripts.length < TOP_SCRIPTS_COUNT
      total_script_count = highlightable_scripts.count
      highlightable_scripts.order(daily_installs: :desc).limit((total_script_count * TOP_SCRIPTS_PERCENTAGE).to_i).pluck(:id).shuffle.each do |id|
        highlighted_scripts << id
        break if highlighted_scripts.length >= TOP_SCRIPTS_COUNT
      end
    end

    return highlighted_scripts.to_a.shuffle
  end

  def highlighted_scripts(restrict_to_ad_method: nil)
    highlighted_scripts_ids = cache_with_log("scripts/highlighted/#{script_subset}/#{I18n.locale}/#{restrict_to_ad_method}") do
      highlighted_script_ids_for_locale(locale: I18n.locale, script_subset:, restrict_to_ad_method:)
    end
    Script.includes(localized_attributes: :locale).where(id: highlighted_scripts_ids.to_a)
  end

  def canonical_url(canonical_param_names)
    canonical_param_names = (canonical_param_names || []).push(:id, :locale)
    canonical_params = params
                       .to_unsafe_h
                       .to_h do |k, v|
      next [k, v] if v.is_a?(Array)

      if canonical_param_names.include?(k.to_sym)
        [k, v.is_a?(String) ? v.encode('UTF-8', invalid: :replace, undef: :replace, replace: '') : v]
      else
        [k, nil]
      end
    end

    begin
      url_for(canonical_params.merge(controller: controller_name, action: action_name, only_path: false, host: sleazy? ? 'sleazyfork.org' : 'greasyfork.org', port: nil))
    rescue StandardError => e
      Rails.logger.error(e)
      request.url
    end
  end

  def non_blocking_stylesheet_tag(url)
    <<~HTML.html_safe
      <link rel="stylesheet" href="#{h url}" media="print" onload="this.media='all'; this.onload=null;">
      <noscript><link rel="stylesheet" href="#{h url}"></noscript>
    HTML
  end
end
