namespace :user_stats do
  desc 'refresh'
  task refresh: :environment do
    User.where.associated(:authors).distinct.find_each(&:update_stats!)
  end
end
