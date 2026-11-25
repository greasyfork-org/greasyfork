class ForumComment < ApplicationRecord
  self.table_name = 'GDN_Comment'
  self.primary_key = 'CommentID'

  scope :not_deleted, -> { where(DateDeleted: nil) }
end
