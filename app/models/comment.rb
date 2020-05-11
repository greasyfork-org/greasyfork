require 'memoist'

class Comment < ApplicationRecord
  extend Memoist

  belongs_to :discussion
  belongs_to :poster, class_name: 'User'

  validates :text, presence: true
  validates :text_markup, inclusion: { in: %w[html markdown] }, presence: true

  delegate :script, to: :discussion

  strip_attributes only: :text

  def path(locale: nil)
    "#{discussion.path(locale: locale)}#comment-#{id}"
  end

  def url(locale: nil)
    "#{discussion.url(locale: locale)}#comment-#{id}"
  end

  def first_comment?
    discussion.comments.order(:id).first == self
  end
  memoize :first_comment?

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

  def notify_script_authors!
    return unless script

    script.users.reject { |user| poster == user }.select { |author_user| author_user.author_email_notification_type_id == User::AUTHOR_NOTIFICATION_COMMENT || (author_user.author_email_notification_type_id == User::AUTHOR_NOTIFICATION_DISCUSSION && first_comment?) }.each do |author_user|
      ForumMailer.comment_on_script(author_user, self).deliver_later
    end
  end
end
