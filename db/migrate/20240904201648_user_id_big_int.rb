class UserIdBigInt < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :moderator_actions, :script_reports, if_exists: true
    drop_table :script_reports, if_exists: true

    tables = [:mentions, :conversation_subscriptions, :authors, :identities, :script_invitations, :discussion_reads, :reports, :roles_users, :discussion_subscriptions, :script_sets]
    tables.each do |table_name|
      remove_foreign_key table_name, :users, if_exists: true
    end
    change_column :users, :id, :bigint, auto_increment: true
    tables.each do |table_name|

      case table_name
      when :script_invitations
        col_name = :invited_user_id
      when :reports
        col_name = :reporter_id
      else
        col_name = :user_id
      end
      change_column table_name, col_name, :bigint
      add_foreign_key table_name, :users, column: col_name, if_not_exists: true, on_delete: :cascade
    end
  end
end
