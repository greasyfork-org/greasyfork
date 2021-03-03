class ScriptPreviouslyDeletedChecker < ApplicationJob
  include Rails.application.routes.url_helpers

  def perform(script_id)
    script = Script.find(script_id)

    return if script.locked?

    similar_locked_scripts = ScriptSimilarity
                             .where(script_id: script_id)
                             .where('similarity >= 0.8')
                             .joins(:other_script)
                             .where(scripts: { locked: true })
                             .map(&:other_script)

    return unless similar_locked_scripts.count > 1

    other_reports = Report.upheld.where(item: similar_locked_scripts)
    scripts_and_reports = similar_locked_scripts.map { |similar_script| [similar_script, other_reports.select { |report| similar_script == report.item }] }

    Report.create!(
      item: script,
      auto_reporter: 'hardy',
      reason: other_reports.first&.reason || Report::REASON_OTHER,
      explanation_markup: 'markdown',
      explanation: <<~TEXT)
        Script is similar to previously deleted scripts:

        #{scripts_and_reports.map { |other_script, reports| "- [#{other_script.default_name}](#{script_url(other_script, locale: nil)}) #{reports.each_with_index.map { |r, i| "[#{i + 1}](#{report_url(r, locale: nil)})" }.join(' ')}" }.join("\n")}
      TEXT
  end
end
