ThinkingSphinx::Index.define :comment, with: :real_time do
  indexes indexable_text
  has discussion_category_id, type: :integer
  has script_id, type: :integer
  has discussion_id, type: :integer
  has discussion_starter_id, type: :integer
  has locale_id, type: :integer
  has poster_id, type: :integer

  scope do
    Comment.indexable
  end
end
