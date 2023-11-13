require 'script_update_cloudfront_query'

namespace :update_counts do
  desc 'load'
  task load: :environment do
    ScriptUpdateCloudfrontQuery.run
  end
end
