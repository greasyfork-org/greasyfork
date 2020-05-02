class Discussion < ApplicationRecord
  RATING_QUESTION = nil
  RATING_BAD = 2
  RATING_OK = 3
  RATING_GOOD = 4

  belongs_to :poster, class_name: 'User'
  belongs_to :script
  has_many :comments

  accepts_nested_attributes_for :comments

  validates :rating, inclusion: { in: [RATING_BAD, RATING_OK, RATING_GOOD] }

  def has_replies?
    comments.count > 1
  end

  def last_comment
    comments.last
  end

  def last_comment_date
    comments.last.created_at
  end
end