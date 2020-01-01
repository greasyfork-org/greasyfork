class UsersCanonicalEmailNotNull < ActiveRecord::Migration[6.0]
  def change
    change_column_null :users, :canonical_email, false
  end
end
