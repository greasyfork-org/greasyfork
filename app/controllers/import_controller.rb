require 'script_importer/userscriptsorg_importer'
require 'script_importer/url_importer'
include ScriptImporter

class ImportController < ApplicationController

	$IMPORTERS = [UserScriptsOrgImporter, UrlImporter]

	before_action :authenticate_user!

	def index
		@scripts_by_source = Script.where(['user_id = ?', current_user.id]).where('script_sync_source_id is not null').includes([:script_sync_source, :script_sync_type])
		@scripts_by_source = @scripts_by_source.group_by{|script| script.script_sync_source}
	end

	# verifies identify and gets a script list
	def verify
		url = params[:url]
		@importer = UserScriptsOrgImporter
		if @importer.remote_user_identifier(url).nil?
			@text = "Invalid #{@importer.import_source_name} profile URL."
			render 'home/error', layout: 'application'
			return
		end
		case @importer.verify_ownership(url, current_user.id)
			when :failure
				@text = "#{@importer.import_source_name} profile check failed."
				render 'home/error', layout: 'application'
				return
			when :nourl
				@text = "Greasy Fork URL not found on #{@importer.import_source_name} profile."
				render 'home/error', layout: 'application'
				return
			when :wronguser
				@text = "Greasy Fork URL found on #{@importer.import_source_name} profile, but it wasn't yours."
				render 'home/error', layout: 'application'
				return
		end
		begin
			@new_scripts, @existing_scripts = @importer.pull_script_list(url)
		rescue OpenURI::HTTPError => ex
			@text = "Could not download script list. '#{ex}' accessing #{url}."
			render 'home/error', status: 500, layout: 'application'
			return
		end
		if @new_scripts.empty? and @existing_scripts.empty?
			@text = "No scripts found on #{@importer.import_source_name}"
			render 'home/error', layout: 'application'
			return
		end
	end

	def add
		importer = $IMPORTERS.select{|i| i.sync_source_id == params[:sync_source_id].to_i}.first
		@results = {:new => [], :failure => [], :needsdescription => [], :existing => []}
		sync_ids = nil
		if params[:sync_ids].nil?
			sync_ids = params[:sync_urls].split(/[\n\r]+/)
		else
			sync_ids = params[:sync_ids]
		end
		sync_ids.each do |sync_id|
			provided_description = params["needsdescription-#{sync_id}"]
			result, script, message = importer.generate_script(sync_id, provided_description, current_user, (params['sync-type'].nil? ? 1 : params['sync-type']))
			case result
				when :needsdescription
					@results[:needsdescription] << script
				when :failure, :notuserscript
					@results[:failure] << "#{importer.sync_id_to_url(sync_id)} - #{message}"
				when :success
					existing_scripts = Script.where(['script_sync_source_id = ? and sync_identifier = ?', importer.sync_source_id, sync_id])
					if !existing_scripts.empty?
						@results[:existing] << existing_scripts.first
					elsif script.save
						@results[:new] << script
					else
						@results[:failure] << "Could not save."
					end
			end
		end
	end

end
