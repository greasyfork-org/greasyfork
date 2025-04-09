class BackfillModeratorActionActionTaken < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    {
      ban: 'Ban',
      delete: 'Delete',
      delete_and_lock: 'Delete and lock',
      mark_adult: 'Mark as adult content',
      mark_not_adult: 'Mark as not adult content',
      permanent_deletion: 'Permanent deletion',
      permanent_deletion_denied: 'Permanent deletion denied',
      unban: 'Unban',
      undelete: 'Undelete',
      undelete_and_unlock: 'Undelete and unlock',
      update_locale: 'Update locale'
    }.each do |enum_value, column_value|
      ModeratorAction.where(action: column_value).update_all(action_taken: enum_value)
    end
    ModeratorAction.where('action LIKE "Delete version%"').find_each do |ma|
      ma.action_taken = :delete_version
      text_match = /Delete version (.*), ID (.*)/.match(ma.action)
      ma.action_details = { 'version': text_match[1], id: text_match[2].to_i }
      ma.save!
    end
  end
end
