module ReportHelper
  def report_item_link(report)
    case report.item
    when User
      link_to report.item.name, user_path(report.item)
    when Comment
      link_to "A comment by #{report.item.poster&.name || "Deleted user #{report.item.poster_id}"}", report.item.path
    when Message
      "A message by #{report.item.poster&.name || "Deleted user #{report.item.poster_id}"}"
    when Script
      render_script(report.item)
    else
      raise 'Unknown type'
    end
  end

  def report_diff(report)
    original_code = report.reference_script.script_versions.last.code
    new_code = report.item.newest_saved_script_version.code
    return tag.p('The scripts are identical.') if original_code == new_code

    Diffy::Diff.new(original_code, new_code, include_plus_and_minus_in_html: true, diff: ['-U 3', '-w']).to_s(:html).html_safe
  end
end
