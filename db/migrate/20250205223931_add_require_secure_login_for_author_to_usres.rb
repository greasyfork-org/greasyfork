class AddRequireSecureLoginForAuthorToUsres < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :require_secure_login_for_author, :boolean, default: false, null: false
  end
end
