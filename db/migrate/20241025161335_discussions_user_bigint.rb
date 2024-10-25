class DiscussionsUserBigint < ActiveRecord::Migration[7.2]
  def change
    change_table :discussions do |t|
      [:poster_id, :stat_last_replier_id, :discussion_category_id, :deleted_by_user_id, :stat_first_comment_id, :locale_id, :report_id].each do |column|
        t.change column, :bigint
      end
    end

    execute 'delete discussions.* from discussions left join reports on discussions.report_id = reports.id where discussions.report_id is not null and reports.id is null'

    add_foreign_key :discussions, :discussion_categories, if_not_exists: true
    add_foreign_key :discussions, :locales, if_not_exists: true
    add_foreign_key :discussions, :reports, on_delete: :cascade, if_not_exists: true
  end
end
