class Report < ApplicationRecord
  REASON_SPAM = 'spam'
  REASON_ABUSE = 'abuse'
  REASON_ILLEGAL = 'illegal'

  REASON_TEXT = {
      REASON_SPAM => 'spam',
      REASON_ABUSE => 'abusive or hateful content',
      REASON_ILLEGAL => 'malware or illegal content',
  }

  RESULT_DISMISSED = 'dismissed'
  RESULT_UPHELD = 'upheld'

  scope :unresolved, -> { where(result: nil) }

  belongs_to :item, polymorphic: true
  belongs_to :reporter, class_name: 'User'

  validates :reason, inclusion: { in: [REASON_SPAM, REASON_ABUSE, REASON_ILLEGAL] }, presence: true

  def dismiss!
    update!(result: RESULT_DISMISSED)
  end

  def uphold!(moderator:)
    case item
    when User
      item.ban!(moderator: moderator, reason: "In response to report ##{id}", ban_related: true)
    else
      raise "Unknown report item #{item}"
    end
    update!(result: RESULT_UPHELD)
  end

  def reason_text
    REASON_TEXT[reason]
  end
end
