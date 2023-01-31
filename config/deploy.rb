set :application, 'greasyfork'
set :repo_url, 'https://github.com/JasonBarnabe/greasyfork.git'
set :deploy_to, '/www/greasyfork'
set :branch, ENV['BRANCH'] if ENV['BRANCH']
set :rbenv_type, :user
set :rbenv_ruby, File.read('.ruby-version').strip
set :sidekiq_roles, %w[worker]
set :sidekiq_systemd_unit_name, 'sidekiq-production'
set :sidekiq_systemd_instances, [1, 2]
set :init_system, :systemd
set :puma_systemctl_user, :system
set :puma_service_unit_name, 'puma'
set :thinking_sphinx_roles, 'workers'
set :assets_roles, [:web, :worker]

set :default_env, {
  'PATH' => '$PATH:/www/sphinx-3.2.1/bin',
}
# set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
# set :rbenv_map_bins, %w{rake gem bundle ruby rails}
# set :rbenv_roles, :all # default value

append :linked_files, 'config/database.yml', 'config/newrelic.yml', 'config/production.sphinx.conf', 'config/secrets.yml', 'config/skylight.yml', 'config/initializers/transifex.rb', 'config/initializers/omniauth.rb', 'config/initializers/detect_language.rb', 'bin/git', 'config/application.yml'

append :linked_dirs, '.bundle', 'log', 'tmp', 'public/data', 'public/cached_pages', 'db/sphinx/production'

namespace :deploy do
  after :published, 'thinking_sphinx:index'
  after :published, 'transifex:update_meta'
  after :rollback, 'thinking_sphinx:index'
  after :rollback, 'sidekiq:start'
end

namespace :sidekiq do
  desc 'Quiet sidekiq (stop fetching new tasks from Redis)'
  task :quiet do
    on roles fetch(:sidekiq_roles) do
      # See: https://github.com/mperham/sidekiq/wiki/Signals#tstp
      execute :systemctl, '--user', 'kill', '-s', 'SIGTSTP', "#{fetch(:sidekiq_systemd_unit_name)}@*", raise_on_non_zero_exit: false
    end
  end

  desc 'Stop sidekiq (graceful shutdown within timeout, put unfinished tasks back to Redis)'
  task :stop do
    on roles fetch(:sidekiq_roles) do
      # See: https://github.com/mperham/sidekiq/wiki/Signals#tstp
      execute :systemctl, '--user', 'kill', '-s', 'SIGTERM', "#{fetch(:sidekiq_systemd_unit_name)}@*", raise_on_non_zero_exit: false
    end
  end

  desc 'Start sidekiq'
  task :start do
    on roles fetch(:sidekiq_roles) do
      execute :systemctl, '--user', 'start', *fetch(:sidekiq_systemd_instances).map { |instance_num| "#{fetch(:sidekiq_systemd_unit_name)}@#{instance_num}" }
    end
  end

  desc 'Restart sidekiq'
  task :restart do
    on roles fetch(:sidekiq_roles) do
      execute :systemctl, '--user', 'restart', *fetch(:sidekiq_systemd_instances).map { |instance_num| "#{fetch(:sidekiq_systemd_unit_name)}@#{instance_num}" }
    end
  end
end

after 'deploy:starting', 'sidekiq:quiet'
after 'deploy:updated', 'sidekiq:stop'
after 'deploy:published', 'sidekiq:start'
after 'deploy:failed', 'sidekiq:restart'
