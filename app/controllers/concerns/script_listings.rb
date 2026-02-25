module ScriptListings
  extend ActiveSupport::Concern

  COLLECTION_PUBLIC_ACTIONS = [:index, :search, :libraries, :by_site].freeze
  COLLECTION_MODERATOR_ACTIONS = [:reported, :reported_not_adult].freeze
  # We want to avoid bots on code_search as it's pretty expensive.
  COLLECTION_LOGGED_IN_ACTIONS = [:code_search].freeze

  DEFAULT_SORT = 'daily_installs'.freeze

  ADVANCED_SEARCH_FIELDS = {
    total_installs: { type: :integer },
    daily_installs: { type: :integer },
    ratings: { type: :float, index_name: :fan_score, min: 0, max: 1, info: 'scripts.listing_ratings_explanation' },
    created: { type: :datetime, index_name: :created_at },
    updated: { type: :datetime, index_name: :code_updated_at },
    entry_locales: { type: :select, index_name: :locale_id, info: 'scripts.listing_locale_explanation' },
  }.freeze

  included do
    layout 'list', only: [:index, :search, :libraries, :reported, :reported_not_adult, :code_search]
  end

  def index
    ensure_integer_params(:set)

    if [:set, :filter_locale, :per_page].any? { |name| params[name].present? }
      # Yandex doesn't seem to listen to noindex
      if request.user_agent&.include?('YandexBot')
        redirect_to scripts_path
        return
      end
      @bots = 'noindex'
    end

    # Make sure the site param is something valid otherwise the listing option links will break because the param
    # won't match the route's definition. This regexp matches the one defined by the route, except with \A and \z.
    params.delete(:site) if params[:site] && !/\A[a-z0-9\-.*]*?\z/i.match?(params[:site])

    respond_to do |format|
      format.html do
        should_cache_page = generally_cachable? && (params.keys - %w[locale controller action site page sort]).none?
        cache_page(should_cache_page ? "script_index/#{site_cache_key}/#{params.values.join('/')}" : nil) do
          status = 200

          begin
            return if load_scripts_for_index
          rescue Searchkick::Error, Elastic::Transport::Transport::Error => e
            raise e unless Rails.env.production?

            status = 500 # We'll render a nice page but with an error code so monitoring will notice.
            Sentry.capture_exception(e)
            flash.now[:alert] = t('scripts.search_failed')
            return if load_scripts_for_index_without_es
          end

          is_search = params[:q].present?

          @set = ScriptSet.find(params[:set]) unless params[:set].nil?
          @by_sites = TopSitesService.get_top_by_sites(script_subset:, locale_id: @search_locale)

          @sort_options = %w[relevance daily_installs total_installs ratings created updated name] if is_search
          @link_alternates = listing_link_alternatives

          if !params[:set].nil?
            if is_search
              @title = t('scripts.listing_title_for_search', search_string: params[:q])
            elsif @set.favorite
              @title = t('scripts.listing_title_for_favorites', set_name: @set.display_name, user_name: @set.user.name)
            else
              @title = @set.display_name
              @description = @set.description
            end
          elsif (params[:site] == '*') && !@scripts.empty?
            @title = t('scripts.listing_title_all_sites')
            @description = t('scripts.listing_description_all_sites')
          elsif !params[:site].nil? && !@scripts.empty?
            @title = t('scripts.listing_title_for_site', site: params[:site])
            @description = t('scripts.listing_description_for_site', site: params[:site])
          else
            @title = t('scripts.listing_title_generic')
            @description = t('scripts.listing_description_generic')
          end
          @canonical_params = [:page, :per_page, :site, :sort, :filter_locale, :language]
          @canonical_params << if is_search
                                 :q
                               else
                                 :set
                               end
          @ad_method = choose_ad_method_for_scripts(@scripts)
          [render_to_string, status]
        end
      end
      format.atom do
        load_scripts_for_index
      end
      format.json do
        return if load_scripts_for_index(for_json: true)

        render json: (params[:meta] == '1') ? { count: @scripts.count } : scripts_as_json(@scripts)
      end
      format.jsonp do
        return if load_scripts_for_index

        render json: (params[:meta] == '1') ? { count: @scripts.count } : scripts_as_json(@scripts), callback: clean_json_callback_param
      end
    end
  end

  def by_site
    respond_to do |format|
      format.html do
        @by_sites = TopSitesService.get_by_sites(script_subset:)
        @by_sites = @by_sites.select { |k, _v| k.present? && k.include?(params[:q].downcase) } if params[:q].present?
        @by_sites = @by_sites.max_by(200) { |_k, v| v[:installs] }.sort_by { |k, _v| k || '' }.to_h
        render layout: 'application'
      end
      format.json do
        result = self.class.cache_with_log('applies_to_counts', expires_in: 1.hour) do
          ScriptAppliesTo.joins(:script, :site_application).where(scripts: { script_type: :public, delete_type: nil }, tld_extra: false).where.not(site_applications: { domain_text: nil }).group('site_applications.domain_text').count
        end
        cache_request(result.to_json)
        render json: result
      end
    end
  end

  def search
    redirect_to params.permit(:page, :per_page, :site, :sort, :q).merge(action: :index), status: :moved_permanently
  end

  def libraries
    with = case script_subset
           when :greasyfork
             { sensitive: false }
           when :sleazyfork
             { sensitive: true }
           else
             {}
           end
    with[:script_type] = Script.script_types[:library]
    with[:author_ids] = params[:by] unless params[:by].to_i.zero?

    @scripts = apply_searchkick_pagination(Script.search(
                                             params[:q].presence || '*',
                                             fields: ['name^10', 'description^5', 'author^5', 'additional_info^1'],
                                             where: with,
                                             order: self.class.get_es_sort(params, default_sort: params[:q].present? ? 'relevance' : 'created'),
                                             page: page_number,
                                             per_page: per_page(default: 100),
                                             includes: [:localized_attributes, :users]
                                           ))

    respond_to do |format|
      format.html do
        # Render normally
      end
      format.atom do
        render 'index'
      end
      format.json do
        render json: (params[:meta] == '1') ? { count: @scripts.count } : scripts_as_json(@scripts)
      end
      format.jsonp do
        render json: (params[:meta] == '1') ? { count: @scripts.count } : scripts_as_json(@scripts), callback: clean_json_callback_param
      end
    end
  end

  def reported_not_adult
    @scripts = apply_pagination(Script.reported_not_adult)
    render :index
  end

  def code_search
    if params[:c].blank?
      redirect_to search_path(anchor: 'code-search'), status: :moved_permanently
      return
    end

    limit_to_ids = User.find_by(id: params[:by])&.script_ids if params[:by].presence

    script_ids = ScriptCodeSearch.search(params[:c], limit_to_ids:)
    @scripts = Script.order(self.class.get_sort(params)).includes(:users, :localized_attributes).where(id: script_ids)
    @scripts = @scripts.where(language: (params[:language] == 'css') ? 'css' : 'js') unless params[:language] == 'all'
    include_deleted = current_user&.moderator? && params[:include_deleted] == '1'
    @scripts = @scripts.listable(script_subset) unless include_deleted
    @scripts = apply_pagination(@scripts)

    respond_to do |format|
      format.html do
        @bots = 'noindex,nofollow'
        @title = t('scripts.listing_title_for_code_search', search_string: params[:c])
        @page_description = t('scripts.listing_description_for_code_search_html', search_string: params[:c])
        @canonical_params = [:c, :sort]
        @include_script_sets = false
        if current_user&.moderator?
          @page_description += view_context.content_tag(:p,
                                                        if include_deleted
                                                          view_context.link_to('Exclude deleted scripts', { c: params[:c], include_deleted: nil })
                                                        else
                                                          view_context.link_to('Include deleted scripts', { c: params[:c], include_deleted: '1' })
                                                        end)
        end

        @link_alternates = [
          { url: current_api_url_with_params(format: :json), type: 'application/json' },
          { url: current_api_url_with_params(format: :jsonp, callback: 'callback'), type: 'application/javascript' },
          { url: current_api_url_with_params(format: :json, meta: '1'), type: 'application/json' },
          { url: current_api_url_with_params(format: :jsonp, meta: '1', callback: 'callback'), type: 'application/javascript' },
        ]
        render action: 'index'
      end
      format.json do
        render json: (params[:meta] == '1') ? { count: @scripts.count } : scripts_as_json(@scripts)
      end
      format.jsonp do
        render json: (params[:meta] == '1') ? { count: @scripts.count } : scripts_as_json(@scripts), callback: clean_json_callback_param
      end
    end
  end

  class_methods do
    def apply_filters(scripts, params, script_subset, default_sort: nil)
      unless params[:site].nil?
        scripts = if params[:site] == '*'
                    scripts.for_all_sites
                  else
                    scripts.joins(:site_applications).where(site_applications: { domain_text: params[:site] })
                  end
      end
      unless params[:set].nil?
        set = ScriptSet.find(params[:set])
        set_script_ids = cache_with_log(set, namespace: script_subset) do
          set.scripts(script_subset).map(&:id)
        end
        scripts = scripts.where(id: set_script_ids)
      end
      scripts = scripts.where(language: (params[:language] == 'css') ? 'css' : 'js') unless params[:language] == 'all'
      scripts = scripts.joins(:authors).where(authors: { user_id: params[:by] }) if params[:by].presence
      scripts = scripts.order(get_sort(params, set:, default_sort:))
      return scripts
    end

    def get_sort(params, set: nil, default_sort: nil)
      sort = params[:sort] || set&.default_sort || default_sort
      case sort
      when 'total_installs'
        'scripts.total_installs DESC, scripts.id'
      when 'created'
        'scripts.created_at DESC, scripts.id'
      when 'updated'
        'scripts.code_updated_at DESC, scripts.id'
      when 'daily_installs'
        'scripts.daily_installs DESC, scripts.id'
      when 'ratings'
        'scripts.fan_score DESC, scripts.id'
      when 'name'
        'scripts.default_name ASC, scripts.id'
      else
        params[:sort] = nil
        "scripts.#{DEFAULT_SORT} DESC, scripts.id"
      end
    end

    def get_es_sort(params, set: nil, default_sort: nil)
      sort = params[:sort] || set&.default_sort || default_sort
      case sort
      when 'total_installs'
        { total_installs: :desc }
      when 'created'
        { created_at: :desc }
      when 'updated'
        { code_updated_at: :desc }
      when 'daily_installs'
        { daily_installs: :desc }
      when 'ratings'
        { fan_score: :desc }
      when 'name'
        { name: :asc }
      else
        if params[:q].presence
          { _score: :desc }
        else
          { daily_installs: :desc }
        end
      end
    end
  end

  protected

  def listing_link_alternatives
    [
      { url: current_api_url_with_params(page: nil, sort: 'created', format: :atom), type: 'application/atom+xml', title: t('scripts.listing_created_feed') },
      { url: current_api_url_with_params(page: nil, sort: 'updated', format: :atom), type: 'application/atom+xml', title: t('scripts.listing_updated_feed') },
      { url: current_api_url_with_params(format: :json), type: 'application/json' },
      { url: current_api_url_with_params(format: :jsonp, callback: 'callback'), type: 'application/javascript' },
      { url: current_api_url_with_params(format: :json, meta: '1'), type: 'application/json' },
      { url: current_api_url_with_params(format: :jsonp, meta: '1', callback: 'callback'), type: 'application/javascript' },
    ]
  end

  def load_scripts_for_index(for_json: false)
    locale = request_locale
    if locale.scripts?(script_subset)
      if params[:filter_locale] == '0' || (params[:filter_locale].nil? && current_user && !current_user.filter_locale_default)
        @offer_filtered_results_for_locale = locale
      else
        @current_locale_filter = locale
        @search_locale = @current_locale_filter.id
      end
    end

    # Search can't do script sets, otherwise we'd use it for everything.
    return load_scripts_for_index_without_es unless params[:set].nil?

    load_scripts_for_index_with_es(for_json:)
  end

  def load_scripts_for_index_with_es(for_json: false)
    with = es_options_for_request

    if params[:entry_locales].present?
      with[:locale] = params[:entry_locales].map(&:to_i)
    elsif @search_locale
      with[:locale] = @search_locale
    end

    if params[:site]
      if params[:site] == '*'
        with[:_not] = { site_application_id: { exists: true } }
      else
        site = SiteApplication.find_by(domain_text: params[:site])

        if site.nil?
          @scripts = apply_pagination(Script.none)
          return false
        end

        if site.blocked
          render_404(site.blocked_message)
          return true
        end

        with[:site_application_id] = site.id
      end
    end

    case params[:language]
    when 'css'
      with[:available_as_css] = true
    when 'all'
      # No filter
    else
      with[:available_as_js] = true
    end

    with[:author_ids] = params[:by].to_i unless params[:by].to_i.zero?

    includes = [:localized_attributes, :users]
    includes.push(:locale, :license) if for_json

    @scripts = apply_searchkick_pagination(Script.search(
                                             params[:q].presence || '*',
                                             fields: ['name^10', 'search_site_names^9', 'description^5', 'author^5', 'additional_info^1'],
                                             boost_by: [:fan_score],
                                             where: with,
                                             order: self.class.get_es_sort(params),
                                             page: page_number,
                                             per_page: per_page(default: 100),
                                             includes:
                                           ))

    false
  end

  def load_scripts_for_index_without_es
    if params[:set]
      set = ScriptSet.find(params[:set])
      if !current_user&.moderator? && set.user&.banned?
        redirect_to scripts_path(locale: request_locale.code), status: :moved_permanently
        return true
      end
    end

    @scripts = Script
               .listable(script_subset)
               .includes({ users: {}, localized_attributes: :locale })
    @scripts = self.class.apply_filters(@scripts, params, script_subset)
    @scripts = apply_pagination(@scripts)

    # Force a load as will be doing empty?, size, etc. and don't want separate queries for each.
    @scripts = @scripts.load

    false
  end

  def es_options_for_request
    with = case script_subset
           when :greasyfork
             { sensitive: false }
           when :sleazyfork
             { sensitive: true }
           else
             {}
           end
    with[:script_type] = Script.script_types[:public]
    time_zone = nil

    ADVANCED_SEARCH_FIELDS.each do |field, field_data|
      next if params[field].blank?

      es_field_name = field_data[:index_name] || field
      case field_data[:type]
      when :integer
        field_value = params[field].to_i
        case params["#{field}_operator"]
        when 'eq'
          with[es_field_name] = field_value
        when 'lt'
          with[es_field_name] = ..field_value
        when 'gt'
          with[es_field_name] = field_value..
        else
          # Ignore any other operator
        end
      when :float
        field_value = params[field].to_f
        case params["#{field}_operator"]
        when 'eq'
          with[es_field_name] = field_value
        when 'lt'
          with[es_field_name] = ..field_value
        when 'gt'
          with[es_field_name] = field_value..
        else
          # Ignore any other operator
        end
      when :datetime
        time_zone ||= begin
          (ActiveSupport::TimeZone[params[:tz]] if params[:tz].is_a?(String)) || Time.zone
        rescue TZInfo::InvalidTimezoneIdentifier
          Time.zone
        end
        field_value = begin
          time_zone.parse(params[field])
        rescue ArgumentError
          nil
        end
        next unless field_value

        # Eliminate stupid values to prevent them causing exceptions in elasticsearch
        next if (field_value - Time.zone.now).abs > 100.years

        case params["#{field}_operator"]
        when 'lt'
          with[es_field_name] = ..field_value
        when 'gt'
          with[es_field_name] = field_value..
        else
          # Ignore any other operator
        end
      when :select
        # entry_locales handled elsewhere
        raise "Unknown advanced search field select type: #{field}" unless field == :entry_locales
      else
        raise "Unknown advanced search field type: #{field_type}"
      end
    end

    with
  end

  def scripts_as_json(scripts)
    scripts = scripts.results if scripts.is_a?(Searchkick::Relation)
    scripts.as_json(include: { users: { sleazy: sleazy? } }, sleazy: sleazy?)
  end
end
