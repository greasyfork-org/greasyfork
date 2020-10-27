class AddMarkAdultByUserToScripts < ActiveRecord::Migration[6.0]
  def change
    add_column :scripts, :marked_adult_by_user_id, :integer
  end
end
