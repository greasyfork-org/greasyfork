class AkismetSubmission < ApplicationRecord
  belongs_to :item, polymorphic: true

  serialize :akismet_params, type: Array, coder: YAML

  def self.mark_as_ham(item)
    akismet_submission = find_by(item:, result_spam: true)
    AkismetHamJob.perform_later(akismet_submission) if akismet_submission
  end
end
