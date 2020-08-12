require 'active_support/concern'
module SoftDeletable
  extend ActiveSupport::Concern

  included do
    belongs_to :deleted_by_user, class_name: 'User', optional: true

    scope :not_deleted, -> { where(deleted_at: nil) }
  end

  class_methods do
    def soft_destroy_all(by_user: nil)
      update_all(deleted_at: Time.now, deleted_by_user: by_user)
    end
  end

  def soft_destroy!(by_user: nil)
    update!(deleted_at: Time.now, deleted_by_user: by_user)
  end
end
