class ForumComment < ApplicationRecord
  self.table_name = 'GDN_Comment'
  self.primary_key = 'CommentID'

  belongs_to :forum_discussion, foreign_key: 'DiscussionID', inverse_of: :forum_comments

  scope :not_deleted, -> { where(DateDeleted: nil) }
end
