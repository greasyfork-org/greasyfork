# config valid only for current version of Capistrano
lock "3.7.1"

set :application, "greasyfork"
set :repo_url, "https://github.com/JasonBarnabe/greasyfork.git"
set :deploy_to, "/home/www/greasyfork"
set :rvm_ruby_version, '2.3.3'

append :linked_files, 'config/database.yml', 'config/newrelic.yml', 'config/production.sphinx.conf', 'config/secrets.yml',  'config/initializers/vanilla.rb', 'config/initializers/transifex.rb', 'config/initializers/omniauth.rb', 'config/initializers/detect_language.rb', 'bin/java', 'bin/simian.jar'

append :linked_dirs, 'public/forum', 'public/system', 'log', 'tmp', 'db/sphinx', 'public/data'

namespace :deploy do
  after :published, "thinking_sphinx:index"
  after :rollback, "thinking_sphinx:index"
end
