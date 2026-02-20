module Pagination
  extend ActiveSupport::Concern
  include Pagy::Method

  included do
    helper_method :render_pagination, :multiple_pages?
  end

  def apply_pagination(relation, default_per_page: 50)
    @pagy, relation = pagy(relation, limit: per_page(default: default_per_page))
    relation
  end

  def apply_searchkick_pagination(search)
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
    return nil unless params[:page].is_a?(String)

    page = params[:page].to_i
    page = 1 if page.nil? || page < 1
    page
  end

  def multiple_pages?
    @pagy && @pagy.pages > 1
  end
end
