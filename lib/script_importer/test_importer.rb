require 'script_importer/base_script_importer'

# A fake importer that treats the URL like data
module ScriptImporter
	class TestImporter < BaseScriptImporter

		def self.sync_source_id
			100
		end

		def self.verify_ownership(remote_ownership_url, current_user_id)
			true
		end

		def self.can_handle_url(url)
			true
		end

		def self.sync_id_to_url(id)
			id
		end

		def self.import_source_name
			'Test'
		end

		# Return a 2-element array consistent of a hash of new scripts and a hash of existing scripts.
		# Each hash is keyed on the remote ID of the script and has a value hash with name and url attributes.
		def self.pull_script_list(remote_ownership_url)
			raise 'N/A'
		end

		def self.download(url)
			url
		end
	end
end
