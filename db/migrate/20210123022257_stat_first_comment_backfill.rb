class StatFirstCommentBackfill < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL
      update discussions 
        join (select discussion_id, min(id) first_id from comments group by discussion_id) a on a.discussion_id = discussions.id 
        set stat_first_comment_id = first_id
    SQL
  end
end
