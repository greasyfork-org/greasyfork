class DiscussionRead < ApplicationRecord
  belongs_to :discussion
  belongs_to :user

  def self.read_ids_for(discussions, user)
    # Manually read discussions
    ids = where(user:, discussion_id: discussions.pluck(:id))
          .left_joins(:discussion)
          .where('discussions.stat_last_reply_date <= discussion_reads.read_at')
          .pluck(:discussion_id)

    # "Mark all as read" discussions
    if user.discussions_read_since
      ids += if discussions.is_a?(Array)
               discussions.select { |d| d.stat_last_reply_date && d.stat_last_reply_date <= user.discussions_read_since }.map(&:id)
             else
               discussions.where(discussions: { stat_last_reply_date: ..user.discussions_read_since }).pluck(:id)
             end
    end

    ids.to_set
  end
end
