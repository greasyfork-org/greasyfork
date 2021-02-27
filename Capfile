# Load DSL and set up stages
require 'capistrano/setup'

# Include default deployment tasks
require 'capistrano/deploy'
require 'capistrano/rbenv'

require 'capistrano/rails'
require 'thinking_sphinx/capistrano'

require 'capistrano/puma'
install_plugin Capistrano::Puma
install_plugin Capistrano::Puma::Systemd

require 'capistrano/bundler'
require 'capistrano/sidekiq'

require 'capistrano/scm/git'
install_plugin Capistrano::SCM::Git

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }

# workaround for https://github.com/capistrano/rails/issues/235
Rake::Task['deploy:assets:backup_manifest'].clear_actions
