# config valid only for current version of Capistrano
lock "3.10.1"

set :application, "greasyfork"
set :repo_url, "https://github.com/JasonBarnabe/greasyfork.git"
set :branch, ENV['BRANCH'] if ENV['BRANCH']
set :deploy_to, "/home/www/greasyfork"
set :rvm_ruby_version, '2.5.1'

append :linked_files, 'config/database.yml', 'config/newrelic.yml', 'config/production.sphinx.conf', 'config/secrets.yml',  'config/initializers/vanilla.rb', 'config/initializers/transifex.rb', 'config/initializers/omniauth.rb', 'config/initializers/detect_language.rb', 'bin/java', 'bin/simian.jar', 'bin/git'

append :linked_dirs, 'public/forum', 'public/system', 'log', 'tmp', 'public/data', 'public/cached_pages'

namespace :deploy do
  after :published, "thinking_sphinx:index"
  after :published, "transifex_update_stats"
  after :rollback, "thinking_sphinx:index"
end
