set :application, 'greasyfork'
set :repo_url, 'https://github.com/JasonBarnabe/greasyfork.git'
set :deploy_to, '/www/greasyfork'
set :branch, ENV['BRANCH'] if ENV['BRANCH']
set :rbenv_type, :user
set :rbenv_ruby, File.read('.ruby-version').strip
set :sidekiq_roles, %w[worker]
set :sidekiq_config, "#{current_path}/config/sidekiq.yml"
set :sidekiq_env, 'production'
set :init_system, :systemd
set :puma_systemctl_user, :system
set :puma_service_unit_name, 'puma'
set :thinking_sphinx_roles, 'workers'

set :default_env, {
  'PATH' => '$PATH:/www/sphinx-3.2.1/bin',
}
# set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
# set :rbenv_map_bins, %w{rake gem bundle ruby rails}
# set :rbenv_roles, :all # default value

append :linked_files, 'config/database.yml', 'config/newrelic.yml', 'config/production.sphinx.conf', 'config/secrets.yml', 'config/initializers/transifex.rb', 'config/initializers/omniauth.rb', 'config/initializers/detect_language.rb', 'bin/git', 'config/application.yml'

append :linked_dirs, '.bundle', 'log', 'tmp', 'public/data', 'public/cached_pages', 'db/sphinx/production'

namespace :deploy do
  after :published, 'thinking_sphinx:index'
  after :published, 'transifex_update_stats'
  after :rollback, 'thinking_sphinx:index'
  after :rollback, 'sidekiq:start'
end

# Reload, not restart https://github.com/seuros/capistrano-puma/issues/303
Rake::Task['puma:restart'].clear_actions
namespace :puma do
  desc 'Restart Puma service via systemd'
  task :restart do
    on roles(fetch(:puma_role)) do
      sudo "#{fetch(:puma_systemctl_bin)} reload #{fetch(:puma_service_unit_name)}"
    end
  end
end
