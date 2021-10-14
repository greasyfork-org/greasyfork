class Report < ApplicationRecord
  include HasAttachments

  REASON_SPAM = 'spam'.freeze
  REASON_ABUSE = 'abuse'.freeze
  REASON_ILLEGAL = 'illegal'.freeze
  REASON_UNAUTHORIZED_CODE = 'unauthorized_code'.freeze
  REASON_MALWARE = 'malware'.freeze
  REASON_MINIFIED = 'minified'.freeze
  REASON_EXTERNAL_CODE = 'external_code'.freeze
  REASON_UNDISCLOSED_ANTIFEATURE = 'undisclosed_antifeature'.freeze
  REASON_NO_DESCRIPTION = 'no_description'.freeze
  REASON_WRONG_CATEGORY = 'wrong_category'.freeze
  REASON_OTHER = 'other'.freeze

  SCRIPT_REASONS = [
    REASON_SPAM,
    REASON_ABUSE,
    REASON_ILLEGAL,
    REASON_UNAUTHORIZED_CODE,
    REASON_MALWARE,
    REASON_MINIFIED,
    REASON_EXTERNAL_CODE,
    REASON_UNDISCLOSED_ANTIFEATURE,
    REASON_NO_DESCRIPTION,
    REASON_OTHER,
  ].freeze

  DISCUSSION_REASONS = [REASON_SPAM, REASON_ABUSE, REASON_ILLEGAL, REASON_WRONG_CATEGORY].freeze
  NON_SCRIPT_REASONS = [REASON_SPAM, REASON_ABUSE, REASON_ILLEGAL].freeze

  GRACE_PERIOD = 3.days
  GRACE_PERIOD_REASONS = [REASON_UNAUTHORIZED_CODE, REASON_UNDISCLOSED_ANTIFEATURE, REASON_OTHER, REASON_EXTERNAL_CODE, REASON_MINIFIED, REASON_NO_DESCRIPTION].freeze

  REASONS_WARRANTING_BLANKING = [REASON_SPAM, REASON_ABUSE, REASON_ILLEGAL, REASON_MALWARE].freeze

  RESULT_DISMISSED = 'dismissed'.freeze
  RESULT_UPHELD = 'upheld'.freeze
  RESULT_FIXED = 'fixed'.freeze

  scope :unresolved, -> { where(result: nil) }
  scope :resolved, -> { where.not(result: nil) }
  scope :upheld, -> { where(result: RESULT_UPHELD) }
  scope :resolved_and_valid, -> { where(result: [RESULT_UPHELD, RESULT_FIXED]) }
  scope :block_on_pending, -> { unresolved.trusted_reporter }
  scope :trusted_reporter, -> { joins(:reporter).where(users: { trusted_reports: true }) }

  belongs_to :item, polymorphic: true
  belongs_to :reporter, class_name: 'User', inverse_of: :reports_as_reporter, optional: true
  belongs_to :reference_script, class_name: 'Script', optional: true
  belongs_to :rebuttal_by_user, class_name: 'User', optional: true
  belongs_to :discussion_category, optional: true

  has_many :discussions

  validates :reason, inclusion: { in: NON_SCRIPT_REASONS }, presence: true, unless: -> { item.is_a?(Script) || item.is_a?(Discussion) }
  validates :reason, inclusion: { in: SCRIPT_REASONS, message: :invalid }, presence: true, if: -> { item.is_a?(Script) }
  validates :reason, inclusion: { in: DISCUSSION_REASONS, message: :invalid }, presence: true, if: -> { item.is_a?(Discussion) }
  validates :reporter, presence: true, if: -> { auto_reporter.nil? }
  validates :explanation_markup, inclusion: { in: %w[html markdown text] }, presence: true
  validates :discussion_category, presence: true, if: -> { reason == REASON_WRONG_CATEGORY }

  def dismiss!(moderator_notes:)
    update!(result: RESULT_DISMISSED, moderator_notes: moderator_notes)
    if item.is_a?(Discussion)
      akismet = item.review_reason == 'akismet'
      item.update!(review_reason: nil)
      CommentNotificationJob.perform_later(item.first_comment) if akismet
    end
    reporter&.update_trusted_report!
    AkismetSubmission.mark_as_ham(item)
  end

  def fixed!(moderator_notes:)
    update!(result: RESULT_FIXED, moderator_notes: moderator_notes)
    item.update!(review_reason: nil) if item.is_a?(Discussion)
    item.discussion.update!(review_reason: nil) if item.is_a?(Comment) && item.first_comment?
    reporter&.update_trusted_report!
  end

  def uphold!(moderator:, moderator_notes: nil, ban_user: false, delete_comments: false, delete_scripts: false, redirect: false)
    Report.transaction do
      case item
      when User, Message
        reported_users.each { |user| user.ban!(moderator: moderator, delete_comments: delete_comments, delete_scripts: delete_scripts, ban_related: true, report: self) }
      when Comment
        reported_users.each { |user| user.ban!(moderator: moderator, delete_comments: delete_comments, delete_scripts: delete_scripts, ban_related: true, report: self) } if ban_user
        item.soft_destroy!(by_user: moderator) unless item.soft_deleted?
      when Discussion
        if reason == REASON_WRONG_CATEGORY
          item.update!(discussion_category_id: discussion_category_id)
        else
          reported_users.each { |user| user.ban!(moderator: moderator, delete_comments: delete_comments, delete_scripts: delete_scripts, ban_related: true, report: self) } if ban_user
          item.soft_destroy!(by_user: moderator) unless item.soft_deleted?
        end
      when Script
        if unauthorized_code? && reference_script
          item.assign_attributes(delete_type: redirect ? 'redirect' : 'keep', locked: true, replaced_by_script: reference_script, self_deleted: moderator.nil?)
        else
          item.assign_attributes(delete_type: warrants_blanking? ? 'blanked' : 'keep', locked: true, self_deleted: moderator.nil?)
        end
        item.save(validate: false)
        if ban_user
          reported_users.each { |user| user.ban!(moderator: moderator, delete_comments: delete_comments, delete_scripts: delete_scripts, ban_related: true, report: self) }
        elsif moderator
          ModeratorAction.create!(moderator: moderator, script: item, action: 'Delete and lock', report: self)
        end
      else
        raise "Unknown report item #{item}"
      end

      update!(result: RESULT_UPHELD, moderator_notes: moderator_notes)
      reporter&.update_trusted_report!
    end

    return if reason == REASON_WRONG_CATEGORY

    Report.unresolved.where(item: item).find_each do |other_report|
      other_report.update!(result: RESULT_UPHELD)
      other_report.reporter&.update_trusted_report!
    end
  end

  def rebut!(rebuttal:, by:)
    update!(rebuttal: rebuttal, rebuttal_by_user: by)
  end

  def reason_text
    return It.it('reports.reason.wrong_category_with_suggestion', antifeature_link: Rails.application.routes.url_helpers.help_antifeatures_path, suggested_category: discussion_category.localized_name) if reason == REASON_WRONG_CATEGORY

    It.it("reports.reason.#{reason}", antifeature_link: Rails.application.routes.url_helpers.help_antifeatures_path)
  end

  def resolved?
    result.present?
  end

  def dismissed?
    result == RESULT_DISMISSED
  end

  def upheld?
    result == RESULT_UPHELD
  end

  def fixed?
    result == RESULT_FIXED
  end

  def warrants_blanking?
    REASONS_WARRANTING_BLANKING.include?(reason)
  end

  def reported_users
    case item
    when User
      [item]
    when Comment, Message, Discussion
      [item.poster]
    when Script
      item.users
    else
      raise 'Unknown type'
    end.compact
  end

  def reported_user_id
    case item
    when User
      item_id
    when Comment, Message, Discussion
      item.poster_id
    when Script
      item.authors.first&.user_id
    else
      raise 'Unknown type'
    end
  end

  def unauthorized_code?
    reason == REASON_UNAUTHORIZED_CODE
  end

  def in_grace_period?
    GRACE_PERIOD_REASONS.include?(reason) && created_at > GRACE_PERIOD.ago
  end

  def awaiting_response?
    in_grace_period? && rebuttal.blank?
  end
end
