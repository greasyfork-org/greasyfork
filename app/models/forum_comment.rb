class ForumComment < ApplicationRecord
  self.table_name = 'GDN_Comment'
  self.primary_key = 'CommentID'

  belongs_to :forum_discussion, foreign_key: 'DiscussionID'
  belongs_to :forum_user, foreign_key: 'InsertUserID'

  scope :not_deleted, -> { where(DateDeleted: nil) }

  def poster
    forum_user.user
  end

  def poster_id
    forum_user.user_id
  end
end
