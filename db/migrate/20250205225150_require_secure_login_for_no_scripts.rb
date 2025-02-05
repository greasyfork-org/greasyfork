class RequireSecureLoginForNoScripts < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL
      update users set require_secure_login_for_author = true where require_secure_login_for_author = false and id not in (select user_id from authors);
    SQL
  end
end
