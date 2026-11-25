class AkismetSpamJob < ApplicationJob
  queue_as :low

  def perform(akismet_params)
    return unless Akismet.api_key

    akismet_params = akismet_params.akismet_params if akismet_params.is_a?(AkismetSubmission)
    Akismet.spam(*akismet_params)
  end
end
