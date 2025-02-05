class RequireSecureLoginForAuthorDefault < ActiveRecord::Migration[8.0]
  def change
    change_column_default :users, :require_secure_login_for_author, true
  end
end
