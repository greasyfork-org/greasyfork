ThinkingSphinx::Index.define :comment, with: :real_time do
  indexes text

  scope { Comment
            .not_deleted
            .left_joins(discussion: [:discussion_category, :script])
            .merge(Discussion.visible)
            .merge(DiscussionCategory.visible_to_user(nil))
            .where('discussions.script_id is null or scripts.delete_type IS NULL')
  }
end
