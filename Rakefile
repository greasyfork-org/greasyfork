# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('config/application', __dir__)

Greasyfork::Application.load_tasks

namespace :test do
  task clean_failure_screenshots: :environment do
    screenshots_dir = Rails.root.join('tmp/screenshots')
    FileUtils.rm_rf(screenshots_dir)
    FileUtils.mkdir_p(screenshots_dir)
  end
end

Rake::Task.tasks.each do |task|
  next unless task.name == 'test' || task.name.start_with?('test:')
  next if %w[test:clean_failure_screenshots test:db test:run].include?(task.name)

  task.enhance(['test:clean_failure_screenshots'])
end
