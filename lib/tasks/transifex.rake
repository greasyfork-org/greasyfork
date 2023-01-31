require 'transifex'
require 'yaml'

namespace :transifex do
  def lookup_value(content, dot_string)
    parts = dot_string.split('.')
    content = content[parts.first]
    return content if parts.length == 1 || content.nil?

    return lookup_value(content, parts[1..parts.length].join('.'))
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
      locale = Locale.where(code: code_with_hyphens).first
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
      (language.coordinators + language.reviewers + language.translators - ['jason.barnabe']).each do |contributor|
        LocaleContributor.create({ locale:, transifex_user_name: contributor })
      end
      locale.save!
    end
  end
end
