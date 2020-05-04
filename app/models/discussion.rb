class Discussion < ApplicationRecord
  RATING_QUESTION = 1
  RATING_BAD = 2
  RATING_OK = 3
  RATING_GOOD = 4

  belongs_to :poster, class_name: 'User'
  belongs_to :script
  has_many :comments

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
