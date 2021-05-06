class DropUserscriptsOrgIdentifiers < ActiveRecord::Migration[6.1]
  def up
    execute 'UPDATE scripts set sync_identifier = null, script_sync_type_id = null, script_sync_source_id = null where script_sync_source_id = 2'
  end
end
