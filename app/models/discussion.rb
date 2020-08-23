class Discussion < ApplicationRecord
  include SoftDeletable

  self.ignored_columns = %w[akismet_spam akismet_blatant]

  RATING_QUESTION = 0
  RATING_BAD = 2
  RATING_OK = 3
  RATING_GOOD = 4

  # Optional because the user may no longer exist.
  belongs_to :poster, class_name: 'User', optional: true
  belongs_to :script, optional: true
  belongs_to :stat_last_replier, class_name: 'User', optional: true
  belongs_to :discussion_category
  has_many :comments, dependent: :destroy
  has_many :discussion_subscriptions

  scope :with_actual_rating, -> { where(rating: [RATING_BAD, RATING_OK, RATING_GOOD]) }
  scope :with_comment_by, ->(user) { where(id: Comment.where(poster: user).pluck(:discussion_id)) }
  scope :visible, -> { not_deleted.where(review_reason: nil) }
  scope :permissive_visible, ->(user) { user.moderator? ? not_deleted : not_deleted.where('review_reason IS NULL OR poster_id = ?', user.id) }

  accepts_nested_attributes_for :comments

  validates :title, length: { maximum: 255 }

  validates :title, absence: true, if: :for_script?
  validates :rating, inclusion: { in: [RATING_QUESTION, RATING_BAD, RATING_OK, RATING_GOOD] }, if: :for_script?

  validates :title, presence: true, unless: :for_script?
  validates :rating, absence: true, unless: :for_script?

  validate do
    if discussion_category_id == DiscussionCategory.script_discussions.id
      errors.add(:category, :invalid) unless script_id
    elsif script_id
      errors.add(:category, :invalid)
    end
  end

  after_soft_destroy do
    comments.not_deleted.each(&:soft_destroy!)
  end

  strip_attributes

  def replies?
    comments.not_deleted.count > 1
  end

  def last_comment
    comments.not_deleted.last
  end

  def last_comment_date
    last_comment.created_at
  end

  def author_posted?
    return false unless script

    comments.not_deleted.where(poster: script.users).any?
  end

  def actual_rating?
    [RATING_BAD, RATING_OK, RATING_GOOD].include?(rating)
  end

  def rating_key
    case rating
    when RATING_GOOD then 'good'
    when RATING_BAD then 'bad'
    when RATING_OK then 'ok'
    end
  end

  def to_param
    return super if for_script?

    "#{id}-#{slugify(title)}"
  end

  def path(locale: nil)
    if script
      Rails.application.routes.url_helpers.script_discussion_path(script, self, locale: locale)
    else
      Rails.application.routes.url_helpers.category_discussion_path(self, category: discussion_category, locale: locale)
    end
  end

  def url(locale: nil)
    if script
      Rails.application.routes.url_helpers.script_discussion_url(script, self, locale: locale)
    else
      Rails.application.routes.url_helpers.category_discussion_url(self, category: discussion_category, locale: locale)
    end
  end

  def display_title(locale: nil)
    return title if title
    return I18n.t('discussions.review_title', script_name: script.name(locale), locale: locale) if actual_rating?

    I18n.t('discussions.question_title', script_name: script.name(locale), locale: locale)
  end

  def update_stats!
    assign_stats
    save! if changed?
  end

  def assign_stats
    # If there's no comments, we're probably in the middle of a delete.
    return if comments.not_deleted.none?

    assign_attributes(calculate_stats)
  end

  def calculate_stats
    {
      stat_reply_count: comments.not_deleted.count - 1,
      stat_last_reply_date: last_comment.created_at,
      stat_last_replier_id: last_comment.poster_id,
    }
  end

  def for_script?
    script_id.present?
  end
end
