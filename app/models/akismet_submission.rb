class AkismetSubmission < ApplicationRecord
  belongs_to :item, polymorphic: true

  serialize :akismet_params, type: Array, coder: YAML

  def self.for_current_text(comment)
    submission = where(item: comment).order(id: :desc).first
    submission if submission && submission.akismet_params.dig(2, :text) == comment.text
  end

  def self.mark_as_ham(item)
    submission = for_reported_item(item)
    AkismetHamJob.perform_later(submission) if submission&.result_spam?
  end

  def self.mark_as_spam(item)
    submission = for_reported_item(item)
    AkismetSpamJob.perform_later(submission) if submission && !submission.result_spam?
  end

  def self.for_reported_item(item)
    comment = item.is_a?(Discussion) ? item.comments.where(first_comment: true).order(:id).first : item
    return unless comment.is_a?(Comment)

    for_current_text(comment)
  end
end
