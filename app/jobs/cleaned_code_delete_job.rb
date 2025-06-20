class CleanedCodeDeleteJob
  include Sidekiq::Job

  sidekiq_options queue: 'background'

  def perform(script_id)
    CleanedCodeJob.delete_for_script_id(script_id)
  end
end
