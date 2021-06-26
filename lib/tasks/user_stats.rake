namespace :user_stats do
  desc 'refresh'
  task refresh: :environment do
    User.left_joins(:authors).where('authors.id is not null or stats_script_count > 0').find_each(&:update_stats!)
  end
end
