class DiscussionRead < ApplicationRecord
  belongs_to :discussion
  belongs_to :user

  def self.read_ids_for(discussions, user)
    where(user: user, discussion_id: discussions.pluck(:id))
         .left_joins(:discussion)
         .where('discussions.stat_last_reply_date < discussion_reads.read_at')
         .pluck(:discussion_id)
         .to_set
  end
end
