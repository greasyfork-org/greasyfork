class UserScriptStats
  def self.for_users(user_ids)
    stats = user_ids.index_with { User::NO_SCRIPT_STATS_TEMPLATE.dup }
    return stats if stats.empty?

    [:all, :greasyfork, :sleazyfork].each do |subset|
      rows = Script.listable(subset)
                   .joins(:authors)
                   .where(authors: { user_id: user_ids })
                   .group('authors.user_id')
                   .pluck(Arel.sql('authors.user_id'), *User::SCRIPT_STAT_QUERIES.map { |_, sql| Arel.sql(sql) })

      rows.each do |user_id, *values|
        User::SCRIPT_STAT_QUERIES.each_with_index do |(name, _), index|
          stats.fetch(user_id)[:"#{subset}_script_#{name}"] = values[index]
        end
      end
    end
    stats
  end
end
