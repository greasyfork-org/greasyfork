class ModeratorAction < ApplicationRecord
  belongs_to :script, optional: true
  belongs_to :user, optional: true
  belongs_to :moderator, class_name: 'User'
  belongs_to :report, optional: true

  validates :moderator, :action, presence: true

  validates :action, length: { maximum: 50 }
  validates :reason, length: { maximum: 500 }
end
