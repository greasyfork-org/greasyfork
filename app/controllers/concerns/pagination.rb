module Pagination
  extend ActiveSupport::Concern
  include Pagy::Method

  MAX_PAGINATION_RESULT = 10_000

  included do
    helper_method :render_pagination, :multiple_pages?
  end

  def apply_pagination(relation, default_per_page: 50)
    page = page_number
    limit = per_page(default: default_per_page)

    # Apply a limit to the number of pages we'll load, because bots seem to go nuts and paginate endlessly despite the directives
    # telling them not to.
    relation = if (page - 1) * limit >= MAX_PAGINATION_RESULT
                 # If we're past the max result, show no results.
                 relation.none
               else
                 # If we're before the max result, apply a limit to make it so we don't generate links past the max result. This also
                 # speeds up the count query.
                 relation.limit(MAX_PAGINATION_RESULT)
               end

    @pagy, relation = pagy(relation, page:, limit:)
    relation
  end

  def apply_searchkick_pagination(search)
    # In contrast to ActiveRecord relations above in apply_pagination, Searchkick has a built-in 10,000 result limit, so we don't need
    # to apply out own limit.
    @pagy = pagy(:searchkick, search)
    search
  end

  def render_pagination
    return nil if @paginate == false || !multiple_pages?

    @pagy.series_nav(slots: 13, anchor_string: ('rel="nofollow"' if @bots == 'noindex')).html_safe
  end

  def per_page(default: 50)
    return default unless params[:per_page].is_a?(String)

    pp = default
    pp = [params[:per_page].to_i, 200].min if params[:per_page].to_i > 0
    pp
  end

  def page_number
    return 1 unless params[:page].is_a?(String)

    page = params[:page].to_i
    page = 1 if page.nil? || page < 1
    page
  end

  def multiple_pages?
    @pagy && @pagy.pages > 1
  end
end
