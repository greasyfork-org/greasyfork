module CommentIndexing
  extend ActiveSupport::Concern

  included do
    searchkick callbacks: :async,
               filterable: [:discussion_category, :script_id, :discussion_id, :discussion_starter_id, :locale_id, :poster_id]

    #scope :indexable, -> { not_deleted
    #                          .left_joins(discussion: :script)
    #                          .includes(discussion: :script)
    #                          .merge(Discussion.visible)
    #                          .where('discussions.script_id is null or scripts.delete_type IS NULL')
    # }
    #scope :search_import, -> { indexable }
    scope :search_import, -> { includes(discussion: :script) }
  end

  def search_data
    {
      discussion_title: discussion.title,
      discussion_category_id: discussion.discussion_category_id,
      script_id: discussion.script_id,
      discussion_id: discussion_id,
      discussion_starter_id: discussion.poster_id,
      locale_id: discussion.locale_id,
      poster_id: poster_id,
      text: indexable_text,
    }
  end

  def indexable_text
    ApplicationController.helpers.format_user_text_as_plain(text, text_markup, use_line_breaks: true)
  end

  def should_index?
    !soft_deleted? && discussion.visible?
  end
end
