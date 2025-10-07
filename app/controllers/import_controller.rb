require 'script_importer/url_importer'
require 'script_importer/script_syncer'

class ImportController < ApplicationController
  include ScriptImporter

  before_action :authenticate_user!
  before_action :check_read_only_mode, except: [:index]

  def index
    @syncing_scripts = Script.joins(:authors).where(authors: { user_id: current_user.id }).where.not(sync_type: nil)
  end

  def add
    language = params['sync-language']
    language = nil unless %w[js css].include?(language)

    importer = ScriptSyncer.choose_importer
    @results = { new: [], failure: [], needsdescription: [], existing: [] }
    sync_ids = if params[:sync_ids].nil?
                 params[:sync_urls].split(/[\n\r]+/)
               else
                 params[:sync_ids]
               end
    sync_ids.each do |sync_id|
      provided_description = params["needsdescription-#{sync_id}"]
      result, script, message = importer.generate_script(sync_id, provided_description, current_user, params['sync-type'] || 'manual', expected_language: language)
      case result
      when :needsdescription
        @results[:needsdescription] << script
      when :failure, :notuserscript
        @results[:failure] << "#{sync_id} - #{message}"
      when :success
        existing_scripts = current_user.scripts.where(sync_identifier: sync_id)
        if !existing_scripts.empty?
          @results[:existing] << existing_scripts.first
        elsif script.save
          @results[:new] << script
        else
          @results[:failure] << 'Could not save.'
        end
      end
    end
  end
end
