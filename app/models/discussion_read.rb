class DiscussionRead < ApplicationRecord
  belongs_to :discussion
  belongs_to :user

  def self.read_ids_for(discussions, user)
    ids = where(user: user, discussion_id: discussions.pluck(:id))
          .left_joins(:discussion)
          .where('discussions.stat_last_reply_date <= discussion_reads.read_at')
          .pluck(:discussion_id)
    ids += discussions.where('discussions.stat_last_reply_date <= ?', user.discussions_read_since).pluck(:id) if user.discussions_read_since
    ids.to_set
  end
end
