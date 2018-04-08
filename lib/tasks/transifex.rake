require 'transifex'
require 'yaml'

namespace :transifex do

  def lookup_value(h, dot_string)
    parts = dot_string.split('.')
    h = h[parts.first]
    return h if parts.length == 1 || h.nil?
    return lookup_value(h, parts[1..parts.length].join('.'))
  end

  def project
    project_slug = 'greasy-fork'
    transifex = Transifex::Client.new
    return transifex.project(project_slug)
  end

  task update_stats: :environment do
    LocaleContributor.delete_all
    p = project
    rails_resource = p.resource('enyml-19')
    p.languages.each do |language|
      code = language.language_code
      code_with_hyphens = code.sub('_', '-')
      locale = Locale.where(:code => code_with_hyphens).first
      if locale.nil?
        Rails.logger.warn("Unknown locale #{code_with_hyphens}, skipping")
        next
      end
      locale.percent_complete = rails_resource.stats(code).completed.to_i
      if locale.percent_complete == 0
        Rails.logger.info("Locale #{code_with_hyphens} empty, skipping")
        next
      end
      Rails.logger.info("Locale #{code_with_hyphens} is #{locale.percent_complete}% complete")
      (language.coordinators + language.reviewers + language.translators).each do |contributor|
        LocaleContributor.create({:locale => locale, :transifex_user_name => contributor})
      end
      locale.save!
    end
  end

  task download_files: :environment do
    p = project
    rails_resource = p.resource('enyml-19')
    vanilla_resource = p.resource('defaultphp')
    vanilla_locale_maps = {
      'zh_CN' => 'zh',
    }
    english_content = YAML.load_file('config/locales/en.yml')['en']

    p.languages.each do |language|
      code = language.language_code
      code_with_hyphens = code.sub('_', '-')

      if rails_resource.stats(code).completed.to_i == 0
        Rails.logger.info("Locale #{code_with_hyphens} empty, skipping")
        next
      end

      # write Rails file
      Rails.logger.info("Downloading #{code_with_hyphens} content")
      c = rails_resource.translation(code).content
      # transifex likes underscores in locale names, we like hyphens
      c.sub!(code, code_with_hyphens) if code != code_with_hyphens
      File.open("config/locales/#{code_with_hyphens}.yml", 'w') { |file| file.write(c) }

      # write Vanilla file
      vanilla_filename = vanilla_locale_maps[code]
      vanilla_filename = code if vanilla_filename.nil?
      File.open("misc/vanilla-plugin/locale/#{vanilla_filename}.php", 'w') { |file| file.write(vanilla_resource.translation(code).content) }

      # write Vanilla file for things already in Rails
      translated_content = YAML.load(c)[code_with_hyphens]
      File.open("misc/vanilla-theme/locale/#{vanilla_filename}.php", 'w') { |file|
        file.write("<?php\n")
        ['layouts.application.script_list', 'layouts.application.forum', 'layouts.application.help', 'layouts.application.submenu', 'layouts.application.advanced_search', 'layouts.application.user_list', 'layouts.application.libraries', 'layouts.application.moderator_log'].each do |k|
          v = lookup_value(translated_content, k)
          v = lookup_value(english_content, k) if v.nil?
          raise "not found #{k}" if v.nil?
          file.write("$Definition['#{k}'] = '#{v.gsub(/'/, "\\\\\'")}';\n")
        end
      }
    end
  end

end
