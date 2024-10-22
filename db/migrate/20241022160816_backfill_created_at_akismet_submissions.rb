class BackfillCreatedAtAkismetSubmissions < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    AkismetSubmission.includes(:item).find_each do |submission|
      submission.update!(created_at: submission.item&.created_at || Time.zone.now)
    end
  end
end
