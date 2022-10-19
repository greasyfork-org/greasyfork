module ReportHelper
  def report_item_link(report)
    case report.item
    when User
      render_user(report.item, report.item_id, skip_badge: true)
    when Discussion
      "Discussion #{link_to(report.item.display_title(locale: :en), report.item.path)} by #{render_user(report.item.poster, report.item.poster_id, skip_badge: true)}".html_safe
    when Comment
      "#{link_to('A comment', report.item.path)} by #{render_user(report.item.poster, report.item.poster_id, skip_badge: true)}".html_safe
    when Message
      "A message by #{render_user(report.item.poster, report.item.poster_id, skip_badge: true)}"
    when Script
      render_script(report.item)
    when nil
      "Deleted #{report.item_type} #{report.item_id}"
    else
      raise 'Unknown type'
    end
  end

  def report_diff(report)
    original_code = report.reference_script.script_versions.last.code
    new_code = report.item.newest_saved_script_version.code
    return tag.p('The scripts are identical.') if original_code == new_code

    Diffy::Diff.new(original_code, new_code, include_plus_and_minus_in_html: true, diff: ['-U 3', '-w'], include_diff_info: true).to_s(:html).html_safe
  end
end
