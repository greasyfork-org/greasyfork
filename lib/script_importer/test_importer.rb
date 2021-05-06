require 'script_importer/base_script_importer'

# A fake importer that treats the URL like data
module ScriptImporter
  class TestImporter < BaseScriptImporter
    def self.can_handle_url(_url)
      true
    end

    def self.import_source_name
      'Test'
    end

    def self.download(url)
      url
    end
  end
end
