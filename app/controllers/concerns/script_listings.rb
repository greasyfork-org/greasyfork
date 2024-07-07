module ScriptListings
  extend ActiveSupport::Concern

  COLLECTION_PUBLIC_ACTIONS = [:index, :search, :libraries, :by_site].freeze
  COLLECTION_MODERATOR_ACTIONS = [:reported, :reported_not_adult].freeze
  # We want to avoid bots on code_search as it's pretty expensive.
  COLLECTION_LOGGED_IN_ACTIONS = [:code_search].freeze

  DEFAULT_SORT = 'daily_installs'.freeze

  included do
    layout 'list', only: [:index, :search, :libraries, :reported, :reported_not_adult, :code_search]
  end

  def index
    if [:set, :filter_locale, :per_page].any? { |name| params[name].present? }
      # Yandex doesn't seem to listen to noindex
      if request.user_agent&.include?('YandexBot')
        redirect_to scripts_path
        return
      end
      @bots = 'noindex'
    end

    respond_to do |format|
      format.html do
        should_cache_page = current_user.nil? && request.format.html? && (params.keys - %w[locale controller action site page sort]).none? && params[:new] != '1'
        cache_page(should_cache_page ? "script_index/#{greasy?}/#{params.values.join('/')}" : nil) do
          status = 200

          begin
            return if load_scripts_for_index
          rescue ThinkingSphinx::SphinxError => e
            raise e unless Rails.env.production?

            status = 500 # We'll render a nice page but with an error code so monitoring will notice.
            Sentry.capture_exception(e)
            flash.now[:alert] = t('scripts.search_failed')
            return if load_scripts_for_index_without_sphinx
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
        return if load_scripts_for_index

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

    begin
      # :ranker => "expr('top(user_weight)')" means that it will be sorted on the top ranking match rather than
      # an aggregate of all matches. In other words, something matching on "name" will be tied with everything
      # else matching on "name".
      @scripts = Script.sphinx_search(
        params[:q],
        with:,
        page: params[:page],
        per_page:,
        order: self.class.get_sort(params, for_sphinx: true, set: nil, default_sort: 'created'),
        populate: true,
        sql: { include: [{ localized_attributes: :locale }, :users] },
        select: '*, weight() myweight',
        ranker: "expr('top(user_weight)')"
      )
      # make it run now so we can catch syntax errors
      @scripts.empty?
    rescue ThinkingSphinx::SyntaxError
      flash[:alert] = "Invalid search query - '#{params[:q]}'."
      # back to the main listing
      redirect_to scripts_path
      return
    end
  end

  def reported_not_adult
    @scripts = Script.reported_not_adult.paginate(page: params[:page], per_page:)
    render :index
  end

  def code_search
    if params[:c].blank?
      redirect_to search_path(anchor: 'code-search'), status: :moved_permanently
      return
    end

    script_ids = ScriptCodeSearch.search(params[:c])
    @scripts = Script.order(self.class.get_sort(params)).includes(:users, :localized_attributes).where(id: script_ids)
    include_deleted = current_user&.moderator? && params[:include_deleted] == '1'
    @scripts = @scripts.listable(script_subset) unless include_deleted
    @scripts = @scripts.paginate(page: params[:page], per_page:)

    respond_to do |format|
      format.html do
        @bots = 'noindex,nofollow'
        @title = t('scripts.listing_title_for_code_search', search_string: params[:c])
        @canonical_params = [:c, :sort]
        @include_script_sets = false
        if current_user&.moderator?
          @page_description = if include_deleted
                                view_context.link_to('Exclude deleted scripts', { c: params[:c], include_deleted: nil })
                              else
                                view_context.link_to('Include deleted scripts', { c: params[:c], include_deleted: '1' })
                              end
        end

        @link_alternates = [
          { url: current_path_with_params(format: :json), type: 'application/json' },
          { url: current_path_with_params(format: :jsonp, callback: 'callback'), type: 'application/javascript' },
          { url: current_path_with_params(format: :json, meta: '1'), type: 'application/json' },
          { url: current_path_with_params(format: :jsonp, meta: '1', callback: 'callback'), type: 'application/javascript' },
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
      scripts = scripts.order(get_sort(params, for_sphinx: false, set:, default_sort:))
      return scripts
    end

    def get_sort(params, for_sphinx: false, set: nil, default_sort: nil)
      # sphinx has these defined as attributes, outside of sphinx they're possibly ambiguous column names
      column_prefix = for_sphinx ? '' : 'scripts.'
      sort = params[:sort] || set&.default_sort || default_sort
      case sort
      when 'total_installs'
        return "#{column_prefix}total_installs DESC, #{column_prefix}id"
      when 'created'
        return "#{column_prefix}created_at DESC, #{column_prefix}id"
      when 'updated'
        return "#{column_prefix}code_updated_at DESC, #{column_prefix}id"
      when 'daily_installs'
        return "#{column_prefix}daily_installs DESC, #{column_prefix}id"
      when 'ratings'
        return "#{column_prefix}fan_score DESC, #{column_prefix}id"
      when 'name'
        return "#{column_prefix}default_name ASC, #{column_prefix}id"
      else
        params[:sort] = nil
        return "myweight DESC, #{column_prefix}#{DEFAULT_SORT} DESC, #{column_prefix}id" if for_sphinx

        return "#{column_prefix}#{DEFAULT_SORT} DESC, #{column_prefix}id"
      end
    end

    def get_es_sort(params, set: nil, default_sort: nil)
      # sphinx has these defined as attributes, outside of sphinx they're possibly ambiguous column names
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
      { url: current_path_with_params(page: nil, sort: 'created', format: :atom), type: 'application/atom+xml', title: t('scripts.listing_created_feed') },
      { url: current_path_with_params(page: nil, sort: 'updated', format: :atom), type: 'application/atom+xml', title: t('scripts.listing_updated_feed') },
      { url: current_path_with_params(format: :json), type: 'application/json' },
      { url: current_path_with_params(format: :jsonp, callback: 'callback'), type: 'application/javascript' },
      { url: current_path_with_params(format: :json, meta: '1'), type: 'application/json' },
      { url: current_path_with_params(format: :jsonp, meta: '1', callback: 'callback'), type: 'application/javascript' },
    ]
  end

  def load_scripts_for_index
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
    return load_scripts_for_index_without_sphinx unless params[:set].nil?

    (params[:new] == '1') ? load_scripts_for_index_with_es : load_scripts_for_index_with_sphinx
  end

  def load_scripts_for_index_with_sphinx
    begin
      with = sphinx_options_for_request
      with[:locale] = @search_locale if @search_locale

      if params[:site]
        if params[:site] == '*'
          with[:site_count] = 0
        else
          site = SiteApplication.find_by(domain_text: params[:site])
          if site.nil?
            @scripts = Script.none.paginate(page: 1)
          elsif site.blocked
            render_404(site.blocked_message)
            return true
          else
            with[:site_application_id] = site.id
          end
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

      # This should be nil unless there are going to be no results.
      if @scripts.nil?
        # :ranker => "expr('top(user_weight)')" means that it will be sorted on the top ranking match rather than
        # an aggregate of all matches. In other words, something matching on "name" will be tied with everything
        # else matching on "name".
        @scripts = Script.sphinx_search(
          params[:q],
          with:,
          page: params[:page],
          per_page:,
          order: self.class.get_sort(params, for_sphinx: true),
          populate: true,
          sql: { include: [{ localized_attributes: :locale }, :users] },
          select: '*, weight() myweight, LENGTH(site_application_id) AS site_count',
          ranker: "expr('top(user_weight)')"
        )
        # make it run now so we can catch syntax errors
        @scripts.empty?
      end
    rescue ThinkingSphinx::SyntaxError, ThinkingSphinx::ParseError, ThinkingSphinx::QueryError
      flash[:alert] = "Invalid search query - '#{params[:q]&.truncate(100)}'."
      # back to the main listing
      redirect_to scripts_path
      return true
    rescue ThinkingSphinx::OutOfBoundsError
      # Paginated too far.
      @scripts = Script.none.paginate(page: 1)
    end

    false
  end

  def load_scripts_for_index_with_es
    with = es_options_for_request

    with[:locale] = @search_locale if @search_locale

    if params[:site]
      if params[:site] == '*'
        with[:_not] = { site_application_id: { exists: true } }
      else
        site = SiteApplication.find_by(domain_text: params[:site])
        if site.nil?
          @scripts = Script.none.paginate(page: 1)
        elsif site.blocked
          render_404(site.blocked_message)
          return true
        else
          with[:site_application_id] = site.id
        end
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

    @scripts = Script.search(
      params[:q].presence || '*',
      fields: ['name^10', 'description^5', 'author^5', 'additional_info^1'],
      where: with,
      order: self.class.get_es_sort(params),
      page: page_number,
      per_page: per_page(default: 100),
      includes: [:localized_attributes, :users]
    )

    false
  end

  def load_scripts_for_index_without_sphinx
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
               .paginate(page: page_number, per_page:)
    @scripts = self.class.apply_filters(@scripts, params, script_subset)
    # Force a load as will be doing empty?, size, etc. and don't want separate queries for each.
    @scripts = @scripts.load

    false
  end

  def scripts_as_json(scripts)
    scripts.as_json(include: { users: { sleazy: sleazy? } }, sleazy: sleazy?)
  end
end
