class UserForeignKeyBigints < ActiveRecord::Migration[7.2]
  def change
    [
      [:messages, :poster_id],
      [:moderator_actions, :moderator_id],
      [:moderator_actions, :user_id],
      [:reports, :rebuttal_by_user_id],
      [:reports, :resolver_id],
      [:scripts, :marked_adult_by_user_id]
    ].each do |table, column|
      change_column table, column, :bigint
    end
  end
end
