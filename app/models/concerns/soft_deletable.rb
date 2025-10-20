require 'active_support/concern'
module SoftDeletable
  extend ActiveSupport::Concern
  extend ActiveModel::Callbacks

  included do
    belongs_to :deleted_by_user, class_name: 'User', optional: true

    scope :not_deleted, -> { where(deleted_at: nil) }
    scope :soft_deleted, -> { where.not(deleted_at: nil) }

    define_model_callbacks :soft_destroy
  end

  def soft_destroy!(by_user: nil, **additional_updates)
    _run_soft_destroy_callbacks do
      update!(deleted_at: Time.current, deleted_by_user_id: by_user&.id, **additional_updates)
    end
  end

  def soft_deleted?
    deleted_at.present?
  end
end
