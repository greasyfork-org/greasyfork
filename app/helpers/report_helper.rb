module ReportHelper
  def report_item_link(report)
    case report.item
    when User
      render_user(report.item, report.item_id, skip_badge: true)
    when Discussion
      t('reports.report_item.discussion', title: link_to(report.item.display_title(locale: :en), report.item.path), user: render_user(report.item.poster, report.item.poster_id, skip_badge: true)).html_safe
    when Comment
      t('reports.report_item.comment', comment: link_to(t('reports.report_item.comment_description', discussion_title: report.item.discussion.display_title(locale: :en)), report.item.path), user: render_user(report.item.poster, report.item.poster_id, skip_badge: true)).html_safe
    when Message
      t('reports.report_item.message', user: render_user(report.item.poster, report.item.poster_id, skip_badge: true)).html_safe
    when Script
      t('reports.report_item.script', script: render_script(report.item)).html_safe
    when nil
      t('reports.report_item.deleted', type: report.item_type, id: report.item_id)
    else
      raise 'Unknown type'
    end
  end

  def report_item_text(report)
    case report.item
    when User
      render_user(report.item, report.item_id, skip_badge: true, skip_link: true)
    when Discussion
      t('reports.report_item.discussion', title: report.item.display_title(locale: :en), user: render_user(report.item.poster, report.item.poster_id, skip_badge: true, skip_link: true))
    when Comment
      t('reports.report_item.comment', comment: t('reports.report_item.comment_description', discussion_title: report.item.discussion.display_title(locale: :en)), user: render_user(report.item.poster, report.item.poster_id, skip_badge: true, skip_link: true))
    when Message
      t('reports.report_item.message', user: render_user(report.item.poster, report.item.poster_id, skip_badge: true, skip_link: true))
    when Script
      t('reports.report_item.script', script: render_script(report.item, skip_link: true)).html_safe
    when nil
      t('reports.report_item.deleted', type: report.item_type, id: report.item_id)
    else
      raise 'Unknown type'
    end
  end

  def report_diff(report)
    if params[:tersed] == '1'
      original_code = report.reference_script.cleaned_code.code
      new_code = report.item.cleaned_code.code
    else
      original_code = report.reference_script.current_code
      new_code = report.item.current_code
    end

    return tag.p(t('scripts.diff_no_change')) if original_code == new_code

    diff = Diffy::Diff.new(original_code, new_code, include_plus_and_minus_in_html: true, diff: ['-U 10000', '-w'], include_diff_info: true)

    return tag.p(t('scripts.diff_no_change')) if diff.to_s.blank?

    diff.to_s(:html).html_safe
  end
end
