class NotNullDefaultCreatedAtAkismetSubmissions < ActiveRecord::Migration[7.2]
  def change
    change_column :akismet_submissions, :created_at, :datetime, null: false, default: -> { 'CURRENT_TIMESTAMP' }
  end
end
