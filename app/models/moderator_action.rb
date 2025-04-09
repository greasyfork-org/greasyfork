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

  enum :action_taken, { delete: 0, undelete: 1, delete_and_lock: 2, undelete_and_unlock: 3, ban: 4, unban: 5, mark_adult: 6, mark_not_adult: 7, permanent_deletion: 8, permanent_deletion_denied: 9, delete_version: 10, update_locale: 11 }, prefix: :action_taken

  serialize :action_details, type: Hash, coder: JSON

  def action_taken_display(locale: I18n.locale)
    I18n.t("moderator_actions.action_taken.#{action_taken}", locale:, **action_details.symbolize_keys)
  end
end
