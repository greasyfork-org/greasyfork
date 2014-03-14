require 'open-uri'

module ScriptImporter
	class BaseScriptImporter

		def self.pull_script_list
			raise 'Missing'
		end

		def self.sync_source_id
			raise 'Missing'
		end

		def self.remote_user_identifier(remote_ownership_url)
			raise 'Missing'
		end

		def self.can_handle_url(url)
			raise 'Missing'
		end

		def self.import_source_name
			raise 'Missing'
		end

		def self.sync_id_to_url(url)
			raise 'Missing'
		end

		def self.verify_ownership(remote_ownership_url, current_user_id)
			return :success if !Greasyfork::Application.config.verify_ownership_on_import
			begin
				content = download(remote_ownership_url)
			rescue OpenURI::HTTPError => ex
				return :failure
			end
			return :failure if content.nil?
			our_url_match = /https?:\/\/greasyfork.org\/users\/([0-9]+)/.match(content)
			return :nourl if our_url_match.nil?
			return current_user_id == our_url_match[1].to_i ? :success : :wronguser
		end

		# Generates a script list and returns an array:
		# - Result code:
		#   - :failure
		#   - :needsdescription
		#   - :success
		# - The script
		# - An error message
		def self.generate_script(sync_id, provided_description, user)
			url = sync_id_to_url(sync_id)
			begin
				code = download(url)
			rescue OpenURI::HTTPError => ex
				return [:failure, nil, "Could not download source. #{ex.message}"]
			end
			code.force_encoding(Encoding::UTF_8)
			sv = ScriptVersion.new
			sv.code = code
			sv.code = sv.inject_meta(:description => provided_description) if (!provided_description.nil? and !provided_description.empty?)
			sv.changelog = "Imported from #{import_source_name}"

			script = Script.new
			script.user = user
			script.script_type_id = 1
			script.script_sync_source_id = sync_source_id
			script.script_sync_type_id = 1
			script.sync_identifier = sync_id
			script.last_attempted_sync_date = DateTime.now

			sv.script = script
			script.script_versions << sv
			sv.do_lenient_saving
			sv.calculate_all
			script.apply_from_script_version(sv)

			return [:failure, script, 'Does not appear to be a user script.'] if script.name.nil?

			return [:needsdescription, script, nil] if (script.description.nil? or script.description.empty?)

			# prefer script_version error messages, but show script error messages if necessary
			return [:failure, script, (sv.errors.full_messages.empty? ? script.errors.full_messages : sv.errors.full_messages).join('. ') + "."] if (!script.valid? | !sv.valid?)

			return [:success, script, nil]
		end

		def self.download(url)
			uri = URI.parse(url)
			return uri.read({:read_timeout => 10})
		end

		def self.separate_new_existing_scripts(scripts)
			existing_ids = Script.select('sync_identifier').where(['script_sync_source_id = ?', sync_source_id]).where(['sync_identifier in (?)', scripts.keys]).map {|s| s.sync_identifier.to_i}
			new = {}
			existing = {}
			scripts.each {|k, v| (existing_ids.include?(k) ? existing : new)[k] = v}
			return [new, existing]
		end

	end
end
