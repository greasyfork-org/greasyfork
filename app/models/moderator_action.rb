class ModeratorAction < ApplicationRecord
  belongs_to :script, optional: true
  belongs_to :user, optional: true
  belongs_to :moderator, class_name: 'User', optional: true
  belongs_to :report, optional: true
  belongs_to :script_lock_appeal, optional: true
  belongs_to :discussion, optional: true
  belongs_to :comment, optional: true

  validates :action, length: { maximum: 50 }
  validates :reason, length: { maximum: 500 }
  validates :moderator, presence: true, unless: :automod?
end
