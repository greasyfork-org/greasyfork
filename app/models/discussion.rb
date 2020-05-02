class Discussion < ApplicationRecord
  belongs_to :poster, class_name: 'User'
  belongs_to :script
  has_many :comments

  accepts_nested_attributes_for :comments

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