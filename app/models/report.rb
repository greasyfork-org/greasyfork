class Report < ApplicationRecord
  include HasAttachments

  REASON_SPAM = 'spam'.freeze
  REASON_ABUSE = 'abuse'.freeze
  REASON_ILLEGAL = 'illegal'.freeze
  REASON_UNAUTHORIZED_CODE = 'unauthorized_code'.freeze
  REASON_MALWARE = 'malware'.freeze
  REASON_MINIFIED = 'minified'.freeze
  REASON_OBFUSCATED = 'obfuscated'.freeze
  REASON_EXTERNAL_CODE = 'external_code'.freeze
  REASON_UNDISCLOSED_ANTIFEATURE = 'undisclosed_antifeature'.freeze
  REASON_NO_DESCRIPTION = 'no_description'.freeze
  REASON_WRONG_CATEGORY = 'wrong_category'.freeze
  REASON_NO_CODE = 'no_code'.freeze
  REASON_LEGAL_CLAIM = 'legal_claim'.freeze
  REASON_OTHER = 'other'.freeze

  SCRIPT_REASONS = [
    REASON_SPAM,
    REASON_ABUSE,
    REASON_ILLEGAL,
    REASON_UNAUTHORIZED_CODE,
    REASON_MALWARE,
    REASON_MINIFIED,
    REASON_OBFUSCATED,
    REASON_EXTERNAL_CODE,
    REASON_UNDISCLOSED_ANTIFEATURE,
    REASON_NO_DESCRIPTION,
    REASON_NO_CODE,
    REASON_LEGAL_CLAIM,
    REASON_OTHER,
  ].freeze

  DISCUSSION_REASONS = [REASON_SPAM, REASON_ABUSE, REASON_ILLEGAL, REASON_WRONG_CATEGORY, REASON_OTHER].freeze
  NON_SCRIPT_REASONS = [REASON_SPAM, REASON_ABUSE, REASON_ILLEGAL, REASON_OTHER].freeze

  GRACE_PERIOD = 3.days
  GRACE_PERIOD_REASONS = [REASON_UNAUTHORIZED_CODE, REASON_UNDISCLOSED_ANTIFEATURE, REASON_OTHER, REASON_EXTERNAL_CODE, REASON_MINIFIED, REASON_OBFUSCATED, REASON_NO_DESCRIPTION, REASON_NO_CODE].freeze

  REASONS_WARRANTING_BLANKING = [REASON_SPAM, REASON_ABUSE, REASON_ILLEGAL, REASON_MALWARE].freeze

  NON_BLOCKING_REASONS = [REASON_NO_DESCRIPTION, REASON_OTHER].freeze

  ADMIN_ONLY_REASONS = [REASON_LEGAL_CLAIM].freeze

  RESULT_DISMISSED = 'dismissed'.freeze
  RESULT_UPHELD = 'upheld'.freeze
  RESULT_FIXED = 'fixed'.freeze

  scope :unresolved, -> { where(result: nil) }
  scope :resolved, -> { where.not(result: nil) }
  scope :upheld, -> { where(result: RESULT_UPHELD) }
  scope :resolved_and_valid, -> { where(result: [RESULT_UPHELD, RESULT_FIXED], moderator_reason_override: nil) }
  scope :block_on_pending, -> { unresolved.where.not(reason: NON_BLOCKING_REASONS).trusted_reporter.or(unresolved.where.not(reason: NON_BLOCKING_REASONS).where(blatant: true)) }
  scope :trusted_reporter, -> { left_joins(:reporter).where(users: { trusted_reports: true }) }

  belongs_to :item, polymorphic: true
  belongs_to :reporter, class_name: 'User', inverse_of: :reports_as_reporter, optional: true
  belongs_to :resolver, class_name: 'User', optional: true
  belongs_to :reference_script, class_name: 'Script', optional: true
  belongs_to :rebuttal_by_user, class_name: 'User', optional: true
  belongs_to :discussion_category, optional: true

  has_many :discussions
  has_many :script_lock_appeals
  has_many :notifications, inverse_of: :item, dependent: :destroy

  validates :reason, inclusion: { in: NON_SCRIPT_REASONS }, presence: true, unless: -> { item.is_a?(Script) || item.is_a?(Discussion) }
  validates :moderator_reason_override, inclusion: { in: NON_SCRIPT_REASONS }, allow_nil: true, unless: -> { item.is_a?(Script) || item.is_a?(Discussion) }
  validates :reason, inclusion: { in: SCRIPT_REASONS, message: :invalid }, presence: true, if: -> { item.is_a?(Script) }
  validates :moderator_reason_override, inclusion: { in: SCRIPT_REASONS, message: :invalid }, allow_nil: true, if: -> { item.is_a?(Script) }
  validates :reason, inclusion: { in: DISCUSSION_REASONS, message: :invalid }, presence: true, if: -> { item.is_a?(Discussion) }
  validates :moderator_reason_override, inclusion: { in: DISCUSSION_REASONS, message: :invalid }, allow_nil: true, if: -> { item.is_a?(Discussion) }
  validates :reason, exclusion: { in: ADMIN_ONLY_REASONS }, unless: -> { reporter&.administrator? || auto_reporter }

  validates :reporter, presence: true, if: -> { auto_reporter.nil? }, on: :create
  validates :explanation, presence: true, if: -> { [REASON_UNDISCLOSED_ANTIFEATURE, REASON_MALWARE, REASON_ILLEGAL, REASON_OTHER].include?(reason) }, on: :create
  validates :explanation, presence: true, if: -> { reason == REASON_UNAUTHORIZED_CODE && script_url.nil? }, on: :create
  validates :explanation_markup, inclusion: { in: %w[html markdown text] }, presence: true
  validates :discussion_category, presence: true, if: -> { reason == REASON_WRONG_CATEGORY }
  validates :private_explanation, length: { maximum: 65_535 }

  def dismiss!(moderator:, moderator_notes:)
    update!(result: RESULT_DISMISSED, moderator_notes:, resolver: moderator)
    if item.is_a?(Discussion) || item.is_a?(Comment)
      send_notification = [Discussion::REVIEW_REASON_AKISMET, Discussion::REVIEW_REASON_RAINMAN].include?(item.review_reason)
      item.update!(review_reason: nil)
      if send_notification
        if item.is_a?(Discussion)
          CommentNotificationJob.perform_later(item.first_comment)
        else
          CommentNotificationJob.perform_later(item)
        end
      end
    end
    reporter&.update_trusted_report!
    AkismetSubmission.mark_as_ham(item)
  end

  def fixed!(moderator:, moderator_notes:)
    update!(result: RESULT_FIXED, moderator_notes:, resolver: moderator)
    item.update!(review_reason: nil) if item.is_a?(Discussion)
    item.discussion.update!(review_reason: nil) if item.is_a?(Comment) && item.first_comment?
    reporter&.update_trusted_report!
  end

  def uphold!(moderator: nil, moderator_notes: nil, moderator_reason_override: nil, ban_user: false, delete_comments: false, delete_scripts: false, redirect: false, self_upheld: false, automod: false)
    raise 'Must specify a moderator' unless moderator || automod || self_upheld

    Report.transaction do
      case item
      when User, Message
        reported_users.each { |user| user.ban!(moderator:, automod:, delete_comments:, delete_scripts:, ban_related: true, report: self) }
      when Comment
        reported_users.each { |user| user.ban!(moderator:, automod:, delete_comments:, delete_scripts:, ban_related: true, report: self) } if ban_user
        item.soft_destroy!(by_user: moderator) unless item.soft_deleted?
        ModeratorAction.create!(moderator:, automod:, comment: item, action_taken: :delete, report: self, private_reason: moderator_notes) unless item.soft_deleted? || ban_user
      when Discussion
        if reason == REASON_WRONG_CATEGORY
          item.update!(discussion_category_id:, script_id: nil, rating: nil, title: item.first_comment.plain_text.truncate(200))
        else
          reported_users.each { |user| user.ban!(moderator:, automod:, delete_comments:, delete_scripts:, ban_related: true, report: self) } if ban_user
          item.soft_destroy!(by_user: moderator) unless item.soft_deleted?
          ModeratorAction.create!(moderator:, automod:, discussion: item, action_taken: :delete, report: self, private_reason: moderator_notes) unless item.soft_deleted? || ban_user
        end
      when Script
        if unauthorized_code? && reference_script
          item.assign_attributes(delete_type: redirect ? 'redirect' : 'keep', locked: true, replaced_by_script: reference_script, self_deleted: moderator.nil?, delete_report: self)
        else
          item.assign_attributes(delete_type: warrants_blanking? ? 'blanked' : 'keep', locked: true, self_deleted: moderator.nil?, delete_report: self)
        end
        item.save(validate: false)
        if ban_user
          reported_users.each { |user| user.ban!(moderator:, automod:, delete_comments:, delete_scripts:, ban_related: true, report: self) }
        elsif moderator
          ModeratorAction.create!(moderator:, automod:, script: item, action_taken: :delete_and_lock, report: self, private_reason: moderator_notes)
        end
      when NilClass
        # Do nothing, it's gone already.
      else
        raise "Unknown report item #{item}"
      end

      update_columns(result: RESULT_UPHELD, resolver_id: moderator&.id, automod_resolved: automod, moderator_notes:, self_upheld:, moderator_reason_override: (moderator_reason_override if moderator_reason_override != reason))
      reporter&.update_trusted_report!
    end

    return if reason == REASON_WRONG_CATEGORY

    return unless item

    self.class.uphold_pending_reports_for(item)
  end

  def self.uphold_pending_reports_for(item)
    Report.unresolved.where(item:).find_each do |other_report|
      other_report.update!(result: RESULT_UPHELD)
      other_report.reporter&.update_trusted_report!
    end
  end

  def rebut!(rebuttal:, by:)
    update!(rebuttal:, rebuttal_by_user: by)
  end

  def reason_text(reason_to_use = reason)
    return It.it('reports.reason.wrong_category_with_suggestion', antifeature_link: Rails.application.routes.url_helpers.help_antifeatures_path, suggested_category: discussion_category.localized_name) if reason_to_use == REASON_WRONG_CATEGORY

    It.it("reports.reason.#{reason_to_use}", antifeature_link: Rails.application.routes.url_helpers.help_antifeatures_path)
  end

  def upheld_reason_text
    reason_text(upheld_reason)
  end

  def pending?
    result.nil?
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

  def upheld_reason
    moderator_reason_override || reason
  end

  def reported_users
    case item
    when User
      [item]
    when Comment, Message, Discussion
      [item.poster]
    when Script
      item.users
    when NilClass
      []
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

  def resolvable_by_moderator?(moderator)
    return true if moderator.administrator?

    return false if admin_only?

    reporter != moderator && reported_users.exclude?(moderator)
  end

  def admin_only?
    ADMIN_ONLY_REASONS.include?(reason)
  end

  def recent_other_reports
    Report.where(created_at: 3.months.ago..DateTime.now).where.not(id:).where(item:).includes(:script_lock_appeals)
  end

  def possible_reasons
    reasons = case item
              when Script then Report::SCRIPT_REASONS
              when Discussion then Report::DISCUSSION_REASONS
              else Report::NON_SCRIPT_REASONS
              end
    reasons -= Report::ADMIN_ONLY_REASONS unless reporter&.administrator?
    reasons
  end

  def url(locale: nil)
    Rails.application.routes.url_helpers.report_url(self, locale:)
  end

  def path(locale: nil)
    Rails.application.routes.url_helpers.report_path(self, locale:)
  end
end
