require 'script_importer/script_syncer'

puts "Started at #{DateTime.now}."

Script.where('script_sync_type_id = 2').where('last_attempted_sync_date < DATE_SUB(UTC_TIMESTAMP(), INTERVAL 1 DAY)').find_each do |script|
	result = ScriptImporter::ScriptSyncer.sync(script)
	puts "#{script.id} - #{result} - #{script.sync_error}"
end
puts "Completed at #{DateTime.now}."
