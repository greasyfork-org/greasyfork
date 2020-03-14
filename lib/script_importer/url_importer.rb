require 'script_importer/base_script_importer'

module ScriptImporter
  class UrlImporter < BaseScriptImporter
    def self.sync_source_id
      1
    end

    def self.can_handle_url(_url)
      true
    end

    def self.sync_id_to_url(id)
      id
    end

    def self.import_source_name
      'URL'
    end
  end
end
