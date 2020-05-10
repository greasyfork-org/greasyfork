class Discussion < ApplicationRecord
  RATING_QUESTION = 0
  RATING_BAD = 2
  RATING_OK = 3
  RATING_GOOD = 4

  belongs_to :poster, class_name: 'User'
  belongs_to :script
  has_many :comments

  scope :with_actual_rating, -> { where(rating: [RATING_BAD, RATING_OK, RATING_GOOD]) }

  accepts_nested_attributes_for :comments

  validates :rating, inclusion: { in: [RATING_QUESTION, RATING_BAD, RATING_OK, RATING_GOOD] }

  def replies?
    comments.count > 1
  end

  def last_comment
    comments.last
  end

  def last_comment_date
    comments.last.created_at
  end

  def author_posted?
    return false unless script

    comments.where(poster: script.users).any?
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

  def path(locale: nil)
    if script
      Rails.application.routes.url_helpers.script_discussion_path(script, self, locale: locale)
    else
      Rails.application.routes.url_helpers.discussion_path(self, locale: locale)
    end
  end

  def url(locale: nil)
    if script
      Rails.application.routes.url_helpers.script_discussion_url(script, self, locale: locale)
    else
      Rails.application.routes.url_helpers.discussion_url(self, locale: locale)
    end
  end
end
