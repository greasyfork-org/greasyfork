class RequireSecureLoginForAuthorBackfill < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL
      UPDATE users SET require_secure_login_for_author = true WHERE created_at >= '2025-01-22'
    SQL
  end
end
