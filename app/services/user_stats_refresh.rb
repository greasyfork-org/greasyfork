class UserStatsRefresh
  BATCH_SIZE = 1000

  def perform
    User.where.associated(:authors).distinct.find_in_batches(batch_size: BATCH_SIZE) do |users|
      stats = UserScriptStats.for_users(users.map(&:id))
      users.each { |user| user.searchkick_script_stats = stats.fetch(user.id) }
      User.searchkick_index.reindex(users, mode: :inline)
    end
  end
end
