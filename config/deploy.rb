# config valid only for current version of Capistrano
lock "3.11.0"

set :application, "greasyfork"
set :repo_url, "https://github.com/JasonBarnabe/greasyfork.git"
set :deploy_to, "/www/greasyfork"
set :branch, ENV['BRANCH'] if ENV['BRANCH']
set :rbenv_type, :user
set :rbenv_ruby, File.read('.ruby-version').strip

set :default_env, {
  'PATH' => '$PATH:/www/sphinx-3.1.1/bin'
}
#set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
#set :rbenv_map_bins, %w{rake gem bundle ruby rails}
#set :rbenv_roles, :all # default value

append :linked_files, 'config/database.yml', 'config/newrelic.yml', 'config/production.sphinx.conf', 'config/secrets.yml',  'config/initializers/vanilla.rb', 'config/initializers/transifex.rb', 'config/initializers/omniauth.rb', 'config/initializers/detect_language.rb', 'bin/git'

append :linked_dirs, 'public/forum', 'public/system', 'log', 'tmp', 'public/data', 'public/cached_pages'

namespace :deploy do
  after :published, "thinking_sphinx:index"
  after :published, "transifex_update_stats"
  after :rollback, "thinking_sphinx:index"
end
