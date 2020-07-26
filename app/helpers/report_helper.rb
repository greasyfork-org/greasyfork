module ReportHelper
  def report_item_link(report)
    case report.item
    when User
      link_to report.item.name, user_path(report.item)
    when Comment
      link_to "A comment by #{report.item.poster&.name || "Deleted user #{report.item.poster_id}"}", report.item.path
    end
  end

  def reported_user(report)
    case report.item
    when User
      report.item
    when Comment
      report.item.poster
    end
  end

  def reported_user_id(report)
    case report.item
    when User
      report.item.id
    when Comment
      report.item.poster_id
    end
  end
end