require 'levenshtein'

class ScriptPreviouslyDeletedChecker < ApplicationJob
  include Rails.application.routes.url_helpers

  def perform(script_id)
    script = Script.find(script_id)

    return if script.locked?

    similar_locked_scripts = (check_by_code(script) + check_by_name(script) + check_by_exact_code(script)).uniq

    return unless similar_locked_scripts.many?

    # No description is removed because there could be that info in additional info, which is not checked by this
    # process. Auto-reports are removed to reduce noise.
    other_reports = Report.upheld.where(item: similar_locked_scripts).where.not(reason: Report::REASON_NO_DESCRIPTION).where(auto_reporter: nil)

    # Reject any unauthorized code reports where the original script shares an author.
    other_reports = other_reports.reject { |other_report| other_report.unauthorized_code? && other_report.reference_script && (other_report.reference_script.users & script.users).any? }
    return if other_reports.empty?

    scripts_and_reports = similar_locked_scripts.map { |similar_script| [similar_script, other_reports.select { |report| similar_script == report.item }] }

    # Use the most common non-'other' reason.
    reason = other_reports.map(&:upheld_reason).reject { |r| r == Report::REASON_OTHER }.tally.max_by(&:last)&.first || Report::REASON_OTHER

    # If it's happened a lot, we'll be more strict on it. "No code" has a lot of false positives, so exempt that.
    blatant = scripts_and_reports.count >= 10 && reason != Report::REASON_NO_CODE

    reference_script = scripts_and_reports.map(&:last).flatten.find { |report| report.reason == reason && report.reference_script }&.reference_script if reason == Report::REASON_UNAUTHORIZED_CODE

    Report.create!(
      item: script,
      reference_script:,
      auto_reporter: 'hardy',
      reason:,
      blatant:,
      explanation_markup: 'markdown',
      explanation: <<~TEXT)
        Script is similar to previously deleted scripts:

        #{scripts_and_reports.first(10).map { |other_script, reports| "- [#{other_script.default_name}](#{script_url(other_script, locale: nil)}) [Diff](#{admin_script_path(script, compare: script_url(other_script, locale: nil), locale: nil, anchor: 'script-comparison', terser: 1)}) #{reports.each_with_index.map { |r, i| "[#{i + 1}](#{report_url(r, locale: nil)})" }.join(' ')}" }.join("\n")}
      TEXT
  end

  def check_by_code(script)
    other_scripts = ScriptSimilarity
                    .where(script_id: script.id)
                    .joins(:other_script)
                    .where(scripts: { locked: true })

    clean_length = CleanedCode.find_by(script_id: script.id)&.code&.length

    # Be more lenient if it's a very short (code-wise) script.
    other_scripts = if clean_length && clean_length < 250
                      other_scripts.where('(similarity >= 0.8 AND !tersed) OR (similarity >= 0.9 AND tersed)')
                    else
                      other_scripts.where('similarity >= 0.8')
                    end

    other_scripts.map(&:other_script).uniq
  end

  def check_by_name(script)
    other_scripts = Script.locked.where(deleted_at: 1.month.ago..)
    other_scripts.select { |other_script| Levenshtein.distance(other_script.default_name, script.default_name, 3) }
  end

  def check_by_exact_code(script)
    script_version = script.newest_saved_script_version
    hashes = [script_version.script_code, script_version.rewritten_script_code].map(&:code_hash)

    script_code_ids = ScriptCode.where(code_hash: hashes.uniq).pluck(:id)
    script_ids = ScriptVersion.where('script_code_id IN (:script_code_ids) OR rewritten_script_code_id IN (:script_code_ids)', script_code_ids:).pluck(:script_id) - [script.id]

    Script.locked.where(id: script_ids)
  end
end
