require 'script_importer/base_script_importer'

module ScriptImporter
  class UrlImporter < BaseScriptImporter
    def self.can_handle_url(_url)
      true
    end

    def self.import_source_name
      'URL'
    end
  end
end
