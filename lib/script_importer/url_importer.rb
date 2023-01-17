require 'script_importer/base_script_importer'

module ScriptImporter
  class UrlImporter < BaseScriptImporter
    def self.can_handle_url(_url)
      true
    end

    def self.import_source_name
      'URL'
    end

    def self.fix_sync_id(url)
      github_html_url = %r{\A(https://github.com/[^/]+/[^/]+/)blob(/.*)\z}.match(url)
      url = "#{github_html_url[1]}raw#{github_html_url[2]}" if github_html_url

      url
    end
  end
end
