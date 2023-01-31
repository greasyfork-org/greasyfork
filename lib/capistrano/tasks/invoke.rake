desc 'run rake transifex:update_meta on the remote server'
task transifex_update_meta: 'deploy:set_rails_env' do |_task, _args|
  on primary(:app) do
    within current_path do
      with rails_env: fetch(:rails_env) do
        rake 'transifex:update_meta'
      end
    end
  end
end
