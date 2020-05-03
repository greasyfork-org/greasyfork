module ReportHelper
  def report_item_link(report)
    case report.item
    when User
      link_to report.item.name, user_path(report.item)
    end
  end
end