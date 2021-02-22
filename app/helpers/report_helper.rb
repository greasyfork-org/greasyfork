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
end
