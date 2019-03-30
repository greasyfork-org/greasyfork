class ScriptInvitation < ApplicationRecord
  VALIDITY_PERIOD = 3.days

  belongs_to :script
  belongs_to :invited_user, class_name: 'User'

  def expired?
    expires_at.past?
  end

  def accept!
    self.class.transaction do
      script.authors.create!(user: invited_user)
      destroy!
    end
  end
end
