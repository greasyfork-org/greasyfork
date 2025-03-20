module CommentIndexing
  extend ActiveSupport::Concern

  included do
    searchkick callbacks: :async,
               max_result_window: 10_000, # Refuse to load past this, as ES raises an error anyway
               filterable: [:discussion_category, :script_id, :discussion_id, :discussion_starter_id, :locale_id, :poster_id]

    scope :search_import, -> { includes(discussion: :script) }
  end

  def search_data
    {
      discussion_title: (discussion.title if first_comment?),
      discussion_category_id: discussion.discussion_category_id,
      script_id: discussion.script_id,
      sensitive: !!discussion.script&.sensitive,
      discussion_id:,
      discussion_starter_id: discussion.poster_id,
      locale_id: discussion.locale_id,
      poster_id:,
      text: plain_text,
      created: created_at,
      discussion_created: discussion.created_at,
      discussion_last_reply: discussion.stat_last_reply_date,
    }
  end

  def should_index?
    !soft_deleted? && discussion.publicly_visible?
  end
end
