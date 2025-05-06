require 'script_importer/url_importer'
require 'script_importer/test_importer'

module ScriptImporter
  class ScriptSyncer
    def self.choose_importer
      Rails.env.test? ? TestImporter : UrlImporter
    end

    # Syncs the script and returns :success, :unchanged, or :failure
    def self.sync(script, changelog = nil, changelog_markup = 'text')
      importer = ScriptSyncer.choose_importer
      # pass the description in so we retain it if it's missing
      begin
        status, new_script, message = importer.generate_script(script.sync_identifier, script.description, script.users.first, 'manual', script.localized_attributes_for('additional_info'), script.locale, do_not_recheck_if_equal_to: script.current_code)
      rescue StandardError => e
        status = :failure
        message = e
      end
      # libraries can be any old JS
      if status == :notuserscript
        status = if script.library?
                   :success
                 else
                   :failure
                 end
      end
      case status
      when :success
        sv = new_script.script_versions.last
        last_saved_sv = script.newest_saved_script_version
        if sv.code == last_saved_sv.code && synced_additional_infos_equal(script, sv)
          script.last_attempted_sync_date = DateTime.now
          script.last_successful_sync_date = script.last_attempted_sync_date
          script.sync_error = nil
          script.save(validate: false)
          return :unchanged
        end

        sv.changelog = changelog.truncate(500) unless changelog.nil?
        sv.changelog_markup = changelog_markup
        sv.script = script
        last_saved_sv.attachments.each { |a| sv.attachments << a.dup }
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
        handle_failed_sync(script, "#{(sv.errors.full_messages.empty? ? script.errors.full_messages : sv.errors.full_messages).join('. ')}.")
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
      script.sync_error = error[0, 1000]
      script.save(validate: false)
    end

    # For the synced additional infos in the script, is anything we got in the new version different?
    def self.synced_additional_infos_equal(script, new_sv)
      script_synced_ais = script.localized_attributes_for('additional_info').reject { |la| la.sync_identifier.nil? }
      new_ais = new_sv.localized_attributes_for('additional_info')
      return script_synced_ais.all? do |la|
        matching_svla = new_ais.find { |svla| svla.locale_id == la.locale_id }
        # if it's not found, it may have failed - that doesn't count as being different
        next true if matching_svla.nil?

        next matching_svla.attribute_value == la.attribute_value
      end
    end

    def self.fix_url(url)
      github_html_url = %r{\A(https://github.com/[^/]+/[^/]+/)blob(/.*)\z}.match(url)
      url = "#{github_html_url[1]}raw#{github_html_url[2]}" if github_html_url

      url
    end
  end
end
