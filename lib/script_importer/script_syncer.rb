require 'script_importer/userscriptsorg_importer'
require 'script_importer/url_importer'
require 'script_importer/test_importer'

module ScriptImporter

  IMPORTERS = Rails.env.test? ? [UserScriptsOrgImporter, UrlImporter, TestImporter] : [UserScriptsOrgImporter, UrlImporter]

  class ScriptSyncer

    # Syncs the script and returns :success, :unchanged, or :failure
    def self.sync(script, changelog = nil, changelog_markup = 'text')
      importer = get_importer_for_sync_source_id(script.script_sync_source_id)
      # pass the description in so we retain it if it's missing
      begin
        status, new_script, message = importer.generate_script(script.sync_identifier, script.description, script.users.first, 1, script.localized_attributes_for('additional_info'), script.locale)
      rescue => ex
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
          if sv.code == last_saved_sv.code && synced_additional_infos_equal(script, sv)
            script.last_attempted_sync_date = DateTime.now
            script.last_successful_sync_date = script.last_attempted_sync_date
            script.sync_error = nil
            script.save(:validate => false)
            return :unchanged
          end

          sv.changelog = changelog.truncate(500) if !changelog.nil?
          sv.changelog_markup = changelog_markup
          sv.script = script
          # Retain existing screenshots
          sv.screenshots = last_saved_sv.screenshots
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
      return IMPORTERS.find{|i| i.can_handle_url(url)}.sync_source_id
    end

    def self.get_importer_for_sync_source_id(id)
      return IMPORTERS.find{|i| i.sync_source_id == id}
    end

  private

  # For the synced additional infos in the script, is anything we got in the new version different?
  def self.synced_additional_infos_equal(script, new_sv)
    script_synced_ais = script.localized_attributes_for('additional_info').select{|la| !la.sync_identifier.nil?}
    new_ais = new_sv.localized_attributes_for('additional_info')
    return script_synced_ais.all?{|la|
      matching_svla = new_ais.find{|svla| svla.locale_id == la.locale_id} 
      # if it's not found, it may have failed - that doesn't count as being different
      next true if matching_svla.nil?
      next matching_svla.attribute_value == la.attribute_value
    }
  end
  end
end
