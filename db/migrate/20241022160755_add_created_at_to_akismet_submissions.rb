class AddCreatedAtToAkismetSubmissions < ActiveRecord::Migration[7.2]
  def change
    add_column :akismet_submissions, :created_at, :datetime
  end
end
