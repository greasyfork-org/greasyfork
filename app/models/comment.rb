class Comment < ApplicationRecord
  belongs_to :discussion
  belongs_to :poster, class_name: 'User'

  validates :text, presence: true
  validates :text_markup, inclusion: { in: %w[html markdown] }, presence: true

  def path(locale: nil)
    "#{discussion.path(locale: locale)}#comment-#{id}"
  end

  def url(locale: nil)
    "#{discussion.url(locale: locale)}#comment-#{id}"
  end

  def first_comment?
    discussion.comments.order(:id).first == self
  end

  def destroy
    if first_comment?
      discussion.destroy
    else
      super
    end
  end

  after_destroy do
    Report.where(item: self).destroy_all
  end
end
