require 'script_importer/userscriptsorg_importer'
require 'script_importer/url_importer'
include ScriptImporter

class ImportController < ApplicationController

	$IMPORTERS = [UserScriptsOrgImporter, UrlImporter]

	before_filter :authenticate_user!

	def index
		@scripts_by_source = Script.where(['user_id = ?', current_user.id]).where('script_sync_source_id is not null').includes([:script_sync_source, :script_sync_type]).order('scripts.name')
		@scripts_by_source = @scripts_by_source.group_by{|script| script.script_sync_source}
	end

	# verifies identify and gets a script list
	def verify
		url = params[:url]
		@importer = UserScriptsOrgImporter
		if @importer.remote_user_identifier(url).nil?
			render :text => "Invalid #{@importer.import_source_name} profile URL.", :layout => true
			return
		end
		case @importer.verify_ownership(url, current_user.id)
			when :failure
				render :text => "#{@importer.import_source_name} profile check failed.", :layout => true
				return
			when :nourl
				render :text => "Greasy Fork URL not found on #{@importer.import_source_name} profile.", :layout => true
				return
			when :wronguser
				render :text => "Greasy Fork URL found on #{@importer.import_source_name} profile, but it wasn\'t yours.", :layout => true
				return
		end
		begin
			@new_scripts, @existing_scripts = @importer.pull_script_list(url)
		rescue OpenURI::HTTPError => ex
			render :text => "Could not download script list. '#{ex}' accessing #{url}.", :layout => true
			return
		end
		if @new_scripts.empty? and @existing_scripts.empty?
			render :text => "No scripts found on #{@importer.import_source_name}", :layout => true
			return
		end
	end

	def add
		importer = $IMPORTERS.select{|i| i.sync_source_id == params[:sync_source_id].to_i}.first
		@results = {:new => [], :new_with_assessment => [], :failure => [], :needsdescription => [], :existing => []}
		sync_ids = nil
		if params[:sync_ids].nil?
			sync_ids = params[:sync_urls].split("\n")
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
						if script.assessments.empty?
							@results[:new] << script
						else
							@results[:new_with_assessment] << script
						end
					else
						@results[:failure] << "Could not save."
					end
			end
		end
	end

end
