desc 'run rake transifex:update_stats on the remote server'
task transifex_update_stats: 'deploy:set_rails_env' do |task, args|
  on primary(:app) do
    within current_path do
      with :rails_env => fetch(:rails_env) do
        rake 'transifex:update_stats'
      end
    end
  end
end
