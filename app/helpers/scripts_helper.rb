require 'memoist'

module ScriptsHelper
  extend Memoist

  def script_list_link(label, sort: nil, site: nil, set: nil, default_sort: nil, language: nil, filter_locale: nil, rel: nil, by: nil)
    is_link = true
    is_minified = action_name == 'minified'
    is_code_search = action_name == 'code_search'
    is_libraries = action_name == 'libraries'
    # sets can have a different default
    sort_param_to_use = (sort == default_sort) ? nil : sort
    rel ||= (set.present? || filter_locale.present?) ? :nofollow : nil
    if sort == params[:sort] && site == params[:site] && set == params[:set] && language == params[:language] && by == params[:by]
      l = label
      is_link = false
    elsif is_libraries
      l = link_to(label, libraries_scripts_path(sort: sort_param_to_use, q: params[:q].presence, set:, by:), rel:)
    elsif is_minified
      l = link_to(label, minified_scripts_path(sort: sort_param_to_use), rel:)
    elsif is_code_search
      l = link_to(label, code_search_scripts_path(sort: sort_param_to_use, c: params[:c], language:, by:), rel:)
    elsif site.nil?
      l = link_to(label, { sort: sort_param_to_use, site: nil, set:, q: params[:q].presence, language:, filter_locale:, by:, **advanced_search_params }, rel:)
    elsif params[:controller] == 'users'
      l = link_to(label, { sort: sort_param_to_use, site:, set:, language:, filter_locale: }, rel:)
    else
      l = link_to label, by_site_scripts_path(sort: sort_param_to_use, site:, set:, q: params[:q].presence, language:, filter_locale:, by:, **advanced_search_params), rel:
    end
    tag.li(class: "list-option#{' list-current' unless is_link}") { l }
  end

  def script_applies_to_list_contents(script)
    sats_with_domains, sats_without_domains = script.script_applies_tos.partition(&:domain?)

    by_sites = TopSitesService.script_counts_for_sites(sites: sats_with_domains.map(&:domain_text), script_subset:)

    return (
    sats_with_domains.map do |sat|
      content_for_script_applies_to_that_has_domain(sat, count_of_other_scripts_with_sat(sat, script, by_sites))
    end +
    sats_without_domains.map { |sat| tag.code(sat.text) }
  )
  end

  def license_display(script)
    return link_to(script.license.code, script.license.url, title: script.license.name) if script.license&.url
    return script.license.code if script.license
    return tag.i { I18n.t('scripts.no_license') } if script.license_text.nil?

    name_and_url_match = /\A(.+); (.+)\z/.match(script.license_text)
    if name_and_url_match
      name, url = name_and_url_match.captures.map(&:strip)
      return link_to(name, url, rel: :nofollow) if URI::DEFAULT_PARSER.make_regexp(%w[http https]).match?(url)
    end

    return script.license_text
  end

  def promoted_script(for_script)
    return nil if sleazy?
    return nil if for_script.sensitive
    return nil if current_user && !current_user.show_ads

    return for_script.promoted_script
  end
  memoize :promoted_script

  def render_script(script, locale: nil, full_url: false, skip_link: false)
    name = script.name(locale || request_locale)
    return name if skip_link

    href = full_url ? script_url(script, locale: locale || request_locale.code) : script_path(script, locale: locale || request_locale.code)
    link_to(name, href, class: 'script-link')
  end

  private

  def content_for_script_applies_to_that_has_domain(sat, count_of_other_scripts)
    if !sat.site_application.blocked && count_of_other_scripts > 0
      title = t('scripts.applies_to_link_title', count: count_of_other_scripts, site: sat.text)
      return link_to(sat.text, by_site_scripts_path(site: sat.domain_text), { title: })
    end
    return sat.text
  end

  def count_of_other_scripts_with_sat(script_applies_to, script, by_sites)
    count = by_sites[script_applies_to.domain_text]
    return 0 if count.nil? || count == 0

    # take this one out of the count if it's a listable
    return count - (script.listable? ? 1 : 0)
  end

  def similarity_string(score)
    key = ScriptsController::DERIVATIVE_SCORES.find { |_key, min_score| score >= min_score }&.first || 'none'
    t("scripts.similarity_score.#{key}")
  end

  def render_script_badge(key)
    text = t("scripts.badges.#{key}.short")
    title = t("scripts.badges.#{key}.long")
    tag.span(class: "badge badge-#{key}", title: (text == title) ? nil : title) { text }
  end

  def delete_reason(script)
    report = script.report_that_deleted
    reason = ''
    reason += link_to(t('reports.name', id: report.id), report_path(report)) if report
    if script.delete_reason.present?
      reason += ' ' if reason.present?
      reason += "\"#{script.delete_reason}\""
    end
    reason.html_safe
  end

  def search_comparator_field(field_name, include_equals: false)
    field = field_name.to_s.parameterize
    return tag.select(id: "search-#{field}-operator", name: "#{field}_operator") do
      options = []
      options << tag.option('>', value: 'gt', selected: params["#{field}_operator"] == 'gt')
      options << tag.option('<', value: 'lt', selected: params["#{field}_operator"] == 'lt')
      options << tag.option('=', value: 'eq', selected: params["#{field}_operator"] == 'eq') if include_equals
      safe_join(options)
    end
  end

  def advanced_search_params(exclude_blank: true)
    rv = {}
    ScriptListings::ADVANCED_SEARCH_FIELDS.each do |name, options|
      next if exclude_blank && params[name].blank?

      rv[name] = params[name]
      operator_param = :"#{name}_operator"
      rv[operator_param] = params[operator_param] if params[operator_param].present?
      rv[:tz] ||= params[:tz] if options[:type] == :datetime && (!exclude_blank || params[:tz].present?)
    end

    rv
  end

  def advanced_search_applied?
    advanced_search_params.any?
  end

  def regular_search_params
    params.permit(:sort, :site, :q, :language, :filter_locale, :by)
  end

  def all_search_params
    regular_search_params.merge(advanced_search_params)
  end
end
