class AddSessionTokenToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :session_token, :string, limit: 32
  end
end
