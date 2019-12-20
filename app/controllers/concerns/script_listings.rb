module ScriptListings
  extend ActiveSupport::Concern

  COLLECTION_PUBLIC_ACTIONS = [:index, :search, :libraries, :code_search, :by_site]
  COLLECTION_MODERATOR_ACTIONS = [:reported, :reported_unauthorized, :reported_not_adult, :requested_permanent_deletion, :minified]

  included do 
    layout 'list', only: [:index, :search, :libraries, :reported, :reported_unauthorized, :reported_not_adult, :requested_permanent_deletion, :minified, :code_search]
  end

  def index
    is_search = params[:q].present?

    # Search can't do script sets, otherwise we'd use it for everything.
    if params[:set].nil?
      begin
        with = case script_subset
          when :greasyfork
            {sensitive: false}
          when :sleazyfork
            {sensitive: true}
          else
            {}
        end

        locale = Locale.find_by(code: I18n.locale)
        if locale.has_scripts?(script_subset)
          if params[:filter_locale] == '0'
            @offer_filtered_results_for_locale = locale
          else
            @current_locale_filter = locale
            with[:locale] = @current_locale_filter.id
          end
        end

        with[:script_type_id] = 1
        if params[:site]
          if params[:site] == '*'
            with[:site_count] = 0
          else
            site = SiteApplication.find_by(text: params[:site])
            if site.nil?
              @scripts = Script.none.paginate(page: 1)
            elsif site.blocked
              render_404(site.blocked_message)
              return
            else
              with[:site_application_id] = site.id
            end
          end
        end

        if params[:language] == 'css'
          with[:available_as_css] = true
        else
          with[:available_as_js] = true
        end

        # This should be nil unless there are going to be no results.
        if @scripts.nil?
          # :ranker => "expr('top(user_weight)')" means that it will be sorted on the top ranking match rather than
          # an aggregate of all matches. In other words, something matching on "name" will be tied with everything
          # else matching on "name".
          @scripts = Script.search(
            params[:q],
            with: with,
            page: params[:page],
            per_page: get_per_page,
            order: self.class.get_sort(params, true),
            populate: true,
            sql: { include: [:script_type, {localized_attributes: :locale}, :users] },
            select: '*, weight() myweight, LENGTH(site_application_id) AS site_count',
            ranker: "expr('top(user_weight)')"
          )
          # make it run now so we can catch syntax errors
          @scripts.empty?
        end
      rescue ThinkingSphinx::SyntaxError, ThinkingSphinx::ParseError => e
        flash[:alert] = "Invalid search query - '#{params[:q]}'."
        # back to the main listing
        redirect_to scripts_path
        return
      rescue ThinkingSphinx::OutOfBoundsError => e
        # Paginated too far.
        @scripts = Script.none.paginate(page: 1)
      end
    else
      @scripts = Script
                     .listable(script_subset)
                     .includes({:users => {}, :script_type => {}, :localized_attributes => :locale, :script_delete_type => {}})
                     .paginate(:page => params[:page], :per_page => get_per_page)
      @scripts = self.class.apply_filters(@scripts, params, script_subset)
    end

    respond_to do |format|
      format.html {
        if !params[:set].nil?
          @set = ScriptSet.find(params[:set])
        end
        @by_sites = self.class.get_top_by_sites(script_subset)

        @sort_options = ['relevance', 'daily_installs', 'total_installs', 'ratings', 'created', 'updated', 'name'] if is_search
        @link_alternates = get_listing_link_alternatives

        if !params[:set].nil?
          if is_search
            @title = t('scripts.listing_title_for_search', :search_string => params[:q])
          elsif @set.favorite
            @title = t('scripts.listing_title_for_favorites', :set_name => @set.display_name, :user_name => @set.user.name)
          else
            @title = @set.display_name
            @description = @set.description
          end
        elsif params[:site] == '*' and !@scripts.empty?
          @title = t('scripts.listing_title_all_sites')
          @description = t('scripts.listing_description_all_sites')
        elsif !params[:site].nil? and !@scripts.empty?
          @title = t('scripts.listing_title_for_site', :site => params[:site])
          @description = t('scripts.listing_description_for_site', :site => params[:site])
        else
          @title = t('scripts.listing_title_generic')
          @description = t('scripts.listing_description_generic')
        end
        @canonical_params = [:page, :per_page, :site, :sort, :filter_locale, :language]
        if is_search
          @canonical_params << :q
        else
          @canonical_params << :set
        end
        @ad_method = choose_ad_method_for_scripts(@scripts)
      }
      format.atom
      format.json {
        render json: params[:meta] == '1' ? { count: @scripts.count } : @scripts.as_json(include: :users)
      }
      format.jsonp {
        render json: params[:meta] == '1' ? { count: @scripts.count } : @scripts.as_json(include: :users), callback: clean_json_callback_param
      }
    end
  end

  def by_site
    respond_to do |format|
      format.html {
        @by_sites = self.class.get_by_sites(script_subset)
        @by_sites = @by_sites.select{|k, v| k.present? && k.include?(params[:q])} if params[:q].present?
        @by_sites = Hash[@by_sites.max_by(200) {|k,v| v[:installs] }.sort_by{|k,v| k || ''}]
        render layout: 'application'
      }
      format.json {
        result = ScriptAppliesTo.joins(:script, :site_application).where(scripts: {script_type_id: 1, script_delete_type_id: nil}, tld_extra: false, site_applications: {domain: true}).group('site_applications.text').count
        cache_request(result.to_json)
        render json: result
      }
    end
  end

  def search
    redirect_to params.permit(:page, :per_page, :site, :sort, :q).merge(action: :index), status: 301
  end

  def libraries
    with = case script_subset
      when :greasyfork
        {sensitive: false}
      when :sleazyfork
        {sensitive: true}
      else
        {}
    end
    with.merge!(script_type_id: 3)

    begin
      # :ranker => "expr('top(user_weight)')" means that it will be sorted on the top ranking match rather than
      # an aggregate of all matches. In other words, something matching on "name" will be tied with everything
      # else matching on "name".
      @scripts = Script.search(
        params[:q],
        with: with,
        page: params[:page],
        per_page: get_per_page,
        order: self.class.get_sort(params, true, nil, default_sort: 'created'),
        populate: true,
        sql: {include: [:script_type, {localized_attributes: :locale}, :users]},
        select: '*, weight() myweight',
        ranker: "expr('top(user_weight)')"
      )
      # make it run now so we can catch syntax errors
      @scripts.empty?
    rescue ThinkingSphinx::SyntaxError => e
      flash[:alert] = "Invalid search query - '#{params[:q]}'."
      # back to the main listing
      redirect_to scripts_path
      return
    end
  end

  def reported
    @scripts = Script.reported
  end

  def reported_unauthorized
    @scripts = Script.reported_unauthorized
    render :reported
  end

  def reported_not_adult
    @scripts = Script.reported_not_adult
    render :reported
  end

  def requested_permanent_deletion
    @scripts = Script.requested_permanent_deletion
    render :reported
  end

  def minified
    @scripts = []
    Script.order(self.class.get_sort(params)).where(:locked => false).each do |script|
      sv = script.get_newest_saved_script_version
      @scripts << script if sv.appears_minified
    end
    @paginate = false
    @title = "Potentially minified user scripts on Greasy Fork"
    @include_script_sets = false
    render :action => 'index'
  end

  def code_search
    @bots = 'noindex,follow'
    if params[:c].nil? or params[:c].empty?
      redirect_to search_path(anchor: 'code-search'), status: 301
      return
    end

    # get latest version for each script
    script_version_ids = Script.connection.select_values("SELECT MAX(id) FROM script_versions GROUP BY script_id")

    # check the code for the search text
    # using the escape character doesn't seem to work, yet it works from the command line. so choose something unlikely to be used as our escape character
    script_ids = Script.connection.select_values("SELECT DISTINCT script_id FROM script_versions JOIN script_codes ON rewritten_script_code_id = script_codes.id WHERE script_versions.id IN (#{script_version_ids.join(',')}) AND code LIKE '%#{Script.connection.quote_string(params[:c].gsub('É', 'ÉÉ').gsub('%', 'É%').gsub('_', 'É_'))}%' ESCAPE 'É' LIMIT 100")
    @scripts = Script.order(self.class.get_sort(params)).includes(:users, :script_type, :script_delete_type).where(id: script_ids)
    @scripts = @scripts.listable(script_subset) if !current_user&.moderator?
    @paginate = false
    @title = t('scripts.listing_title_for_code_search', :search_string => params[:c])
    @canonical_params = [:c, :sort]
    @include_script_sets = false
    render :action => 'index'
  end

  class_methods do

    def apply_filters(scripts, params, script_subset, default_sort: nil)
      if !params[:site].nil?
        if params[:site] == '*'
          scripts = scripts.for_all_sites
        else
          scripts = scripts.joins(:site_applications).where(site_applications: {text: params[:site]})
        end
      end
      if !params[:set].nil?
        set = ScriptSet.find(params[:set])
        set_script_ids = cache_with_log([set, script_subset]) do
          set.scripts(script_subset).map{|s| s.id}
        end
        scripts = scripts.where(:id => set_script_ids)
      end
      scripts = scripts.where(language: params[:language] == 'css' ? 'css' : 'js')
      scripts = scripts.order(get_sort(params, false, set, default_sort: default_sort))
      return scripts
    end

    def get_top_by_sites(script_subset)
      return cache_with_log("scripts/get_top_by_sites/#{script_subset}") do
        get_by_sites(script_subset).sort{|a,b| b[1][:installs] <=> a[1][:installs]}.first(10)
      end
    end

    def get_sort(params, for_sphinx = false, set = nil, default_sort: nil)
      # sphinx has these defined as attributes, outside of sphinx they're possibly ambiguous column names
      column_prefix = for_sphinx ? '' : 'scripts.'
      sort = params[:sort] || (!set.nil? ? set.default_sort : nil) || default_sort
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
          if for_sphinx
            return "myweight DESC, #{column_prefix}daily_installs DESC, #{column_prefix}id"
          end
          return "#{column_prefix}daily_installs DESC, #{column_prefix}id"
      end
    end

  end

  protected

  def render_script_list(scripts, options = {})
    @scripts = scripts
    if !(options && options[:skip_filters])
      @scripts = @scripts.paginate(page: params[:page], per_page: get_per_page)
      @scripts = self.class.apply_filters(@scripts, params, script_subset)
    end

    respond_to do |format|
      format.html {
        @feeds = {t('scripts.listing_created_feed') => {sort: 'created'}, t('scripts.listing_updated_feed') => {sort: 'updated'}}
        @canonical_params = [:q, :page, :per_page, :sort]
        @link_alternates = get_listing_link_alternatives
        render :index
      }
      format.atom {
        render :index
      }
      format.json {
        render json: params[:meta] == '1' ? {count: @scripts.count} : @scripts.as_json(include: :users)
      }
      format.jsonp {
        render json: params[:meta] == '1' ? {count: @scripts.count} : @scripts.as_json(include: :users), callback: clean_json_callback_param
      }
    end
  end

  def get_listing_link_alternatives
    [
      {:url => current_path_with_params(page: nil, sort: 'created', format: :atom), :type => 'application/atom+xml', :title => t('scripts.listing_created_feed')},
      {:url => current_path_with_params(page: nil, sort: 'updated', format: :atom), :type => 'application/atom+xml', :title => t('scripts.listing_updated_feed')},
      {:url => current_path_with_params(format: :json), :type => 'application/json'},
      {:url => current_path_with_params(format: :jsonp, callback: 'callback'), :type => 'application/javascript'},
      {:url => current_path_with_params(format: :json, meta: '1'), :type => 'application/json'},
      {:url => current_path_with_params(format: :jsonp, meta:'1', callback: 'callback'), :type => 'application/javascript'}
    ]
  end

end
