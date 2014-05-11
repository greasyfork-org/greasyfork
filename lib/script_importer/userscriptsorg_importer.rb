require 'script_importer/base_script_importer'

module ScriptImporter
	class UserScriptsOrgImporter < BaseScriptImporter

		def self.sync_source_id
			2
		end

		def self.remote_user_identifier(remote_ownership_url)
			profile_url_match = /^https?:\/\/userscripts.org(?:\:8080)?\/users\/([0-9]+)(\/.*)?$/.match(remote_ownership_url)
			return nil if profile_url_match.nil?
			return profile_url_match[1]
		end

		def self.can_handle_url(url)
			return /^https?:\/\/userscripts\.org(\:8080)?\/scripts\/source\/[0-9]+\.user\.js$/ =~ url
		end

		def self.sync_id_to_url(id)
			return "#{Greasyfork::Application.config.userscriptsorg_host}/scripts/source/#{id}.user.js"
		end

		def self.import_source_name
			'userscripts.org'
		end

		# Return a 2-element array consistent of a hash of new scripts and a hash of existing scripts.
		# Each hash is keyed on the remote ID of the script and has a value hash with name and url attributes.
		def self.pull_script_list(remote_ownership_url)
			scripts = {}
			i = 1
			# loop through each page of results - 20 is a reasonable limit as the most profilic
			# author on userscripts has < 1000
			while i < 20
				content = download("#{Greasyfork::Application.config.userscriptsorg_host}/users/#{remote_user_identifier(remote_ownership_url)}/scripts?page=#{i}")
				page_scripts = content.scan(/<a href="\/scripts\/show\/([0-9]+)[^>]+>([^<]+)/)
				break if page_scripts.empty?
				page_scripts.each do |match|
					scripts[match[0].to_i] = {:name => match[1], :url => "#{Greasyfork::Application.config.userscriptsorg_host}/scripts/source/#{match[0]}.user.js"}
				end
				i = i + 1
			end
			return separate_new_existing_scripts(scripts)
		end

		def self.fix_url(u)
			return Greasyfork::Application.config.userscriptsorg_host + '/' + u.split('/', 4).last
		end

	end
end
