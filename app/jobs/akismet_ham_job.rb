class AkismetHamJob < ApplicationJob
  queue_as :low

  def perform(akismet_submission)
    return unless Akismet.api_key

    Akismet.ham(*akismet_submission.akismet_params)
  end
end
