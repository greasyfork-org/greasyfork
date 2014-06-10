# so that the webhook job knows what that is
require 'script_importer/script_syncer'
# keep around failures for later inspection
Delayed::Worker.destroy_failed_jobs = false
