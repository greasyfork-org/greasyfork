require 'script_importer/userscriptsorg_importer'
require 'script_importer/url_importer'
require 'script_importer/test_importer'

module ScriptImporter
	class ScriptSyncer
		$IMPORTERS = [UserScriptsOrgImporter, UrlImporter, TestImporter]

		# Syncs the script and returns :success, :unchanged, or :failure
		def self.sync(script, changelog = nil)
			importer = $IMPORTERS.select{|i| i.sync_source_id == script.script_sync_source_id}.first
			# pass the description in so we retain it if it's missing
			begin
				status, new_script, message = importer.generate_script(script.sync_identifier, script.description, script.user)
			rescue Exception => ex
				status = :failure
				message = ex
			end
			# libraries can be any old JS
			if status == :notuserscript
				if script.library?
					status = :success
				else
					status = :failure
				end
			end
			case status
				when :success
					sv = new_script.script_versions.last
					last_saved_sv = script.get_newest_saved_script_version
					if sv.code == last_saved_sv.code
						script.last_attempted_sync_date = DateTime.now
						script.last_successful_sync_date = script.last_attempted_sync_date
						script.sync_error = nil
						script.save(:validate => false)
						return :unchanged
					end
					sv.additional_info = last_saved_sv.additional_info
					sv.additional_info_markup = last_saved_sv.additional_info_markup
					sv.changelog = changelog if !changelog.nil?
					sv.script = script
					sv.do_lenient_saving
					sv.calculate_all(script.description)
					script.apply_from_script_version(sv)
					if script.valid? & sv.valid?
						script.script_versions << sv
						script.last_attempted_sync_date = DateTime.now
						script.last_successful_sync_date = script.last_attempted_sync_date
						script.sync_error = nil
						script.save!
						return :success
					end
					handle_failed_sync(script, (sv.errors.full_messages.empty? ? script.errors.full_messages : sv.errors.full_messages).join('. ') + ".")
					return :failure
				when :failure
					handle_failed_sync(script, message)
					return :failure
				when :needsdescription
					# this shouldn't happen...
					handle_failed_sync(script, "Doesn't have a description")
					return :failure
			end
			return :failure
		end

		# undo the changes, record the failure
		def self.handle_failed_sync(script, error)
			script.reload
			script.last_attempted_sync_date = DateTime.now
			script.sync_error = error
			script.save(:validate => false)
		end

		def self.get_sync_source_id_for_url(url)
			return $IMPORTERS.select{|i| i.can_handle_url(url)}.first.sync_source_id
		end
	end
end
