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
    discussion_path = discussion.path(locale: locale)
    discussion_path += "#comment-#{id}" unless first_comment?
    discussion_path
  end

  def url(locale: nil)
    discussion_url = discussion.url(locale: locale)
    discussion_url += "#comment-#{id}" unless first_comment?
    discussion_url
  end

  def destroy
    if first_comment?
      discussion.destroy
    else
      super
    end
  end

  after_commit do
    discussion.update_stats!
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

  def update_stats!
    update!(calculate_stats)
  end

  def assign_stats
    assign_attributes(calculate_stats)
  end

  def calculate_stats
    {
        first_comment: discussion.comments.order(:id).first == self,
    }
  end
end
