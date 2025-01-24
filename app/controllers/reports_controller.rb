class ReportsController < ApplicationController
  before_action :check_read_only_mode, except: [:index, :show, :diff]
  before_action :authenticate_user!, except: :show
  before_action :moderators_only, only: [:index, :dismiss]
  before_action :load_report, only: :show
  before_action :mark_notifications_read, only: :show

  before_action do
    @bots = 'noindex'
  end

  def index
    scope = Report
            .includes(:item)
            .order(:created_at)
    if params[:user_id].present?
      scope = scope.where(reporter_id: params[:user_id])
    elsif params[:script_id].present?
      scope = scope.where(item_type: 'Script', item_id: params[:script_id])
    elsif params[:non_dismissed] != '1'
      @show_separator = true
      scope = scope.unresolved
    end

    scope = scope.where(result: [Report::RESULT_FIXED, Report::RESULT_UPHELD]) if params[:non_dismissed] == '1'

    report_ids = scope
                 .sort_by { |r| [r.awaiting_response? ? 1 : 0, r.created_at] }
                 .map(&:id)
    @reports = Report
               .where(id: report_ids)
               .includes(:item, :reference_script, :reporter, :rebuttal_by_user)
    @reports = @reports.order(Arel.sql("FIELD(id, #{report_ids.join(',')})")) if report_ids.any?
    @reports = @reports.paginate(page: params[:page], per_page: per_page(default: 25))
    @bots = 'noindex'
  end

  def show
    @bots = 'noindex'
    render_404 unless @report.item
  end

  def new
    @report = Report.new(item:, reporter: current_user, explanation_markup: current_user&.preferred_markup)
    previous_report = Report.unresolved.where(item:, reporter: current_user).first
    if previous_report
      redirect_to report_path(previous_report)
      return
    end

    check_for_blocked_report
  end

  def create
    @report = Report.new(report_params)
    @report.reporter = current_user
    @report.item = item

    return if check_for_blocked_report(@report)

    if @report.item.is_a?(Script) && @report.script_url.present?
      script_from_input = get_script_from_input(@report.script_url, allow_deleted: true)
      if script_from_input.is_a?(Script)
        @report.reference_script = script_from_input
        @report.script_url = nil
      end
    end
    unless @report.save
      render :new
      return
    end

    if current_user.trusted_reports
      item.update!(review_reason: Discussion::REVIEW_REASON_TRUSTED) if @report.item.is_a?(Discussion) && @report.reason != Report::REASON_WRONG_CATEGORY
      if @report.item.is_a?(Comment)
        item.discussion.update!(review_reason: Discussion::REVIEW_REASON_TRUSTED) if @report.item.first_comment?
        item.update!(review_reason: Discussion::REVIEW_REASON_TRUSTED)
      end
    end

    if @report.item.is_a?(Script)
      UserNotificationService.notify_authors_for_report_filed(@report) do |user, locale|
        ScriptReportMailer.report_created(@report, user, locale, site_name).deliver_later
      end
    end

    redirect_to report_path(@report), notice: t('reports.report_filed')
  end

  def dismiss
    @report = Report.find(params[:id])

    @report.dismiss!(moderator: current_user, moderator_notes: params[:moderator_notes].presence)
    if @report.item.is_a?(Script) && !@report.auto_reporter
      UserNotificationService.notify_authors_for_report_resolved(@report) do |user, locale|
        ScriptReportMailer.report_dismissed_offender(@report, user, locale, site_name).deliver_later
      end
      UserNotificationService.notify_reporter_for_report_resolved(@report) do |user, locale|
        ScriptReportMailer.report_dismissed_reporter(@report, user, locale, site_name).deliver_later
      end
    end
    redirect_to reports_path(anchor: (params[:index] == '0') ? nil : "open-report-#{params[:index]}")
  end

  def mark_fixed
    @report = Report.find(params[:id])

    if current_user.moderator? && !@report.resolvable_by_moderator?(current_user)
      @text = 'Cannot mark as fixed, you are involved in this report.'
      render 'home/error', status: :not_acceptable, layout: 'application'
      return
    end

    @report.fixed!(moderator: current_user, moderator_notes: params[:moderator_notes].presence)
    if @report.item.is_a?(Script) && !@report.auto_reporter
      UserNotificationService.notify_authors_for_report_resolved(@report) do |user, locale|
        ScriptReportMailer.report_fixed_offender(@report, user, locale, site_name).deliver_later
      end
      UserNotificationService.notify_reporter_for_report_resolved(@report) do |user, locale|
        ScriptReportMailer.report_fixed_reporter(@report, user, locale, site_name).deliver_later
      end
    end
    redirect_to reports_path(anchor: (params[:index] == '0') ? nil : "open-report-#{params[:index]}")
  end

  def uphold
    @report = Report.find(params[:id])

    user_is_script_author = user_is_script_author?(@report)

    unless user_is_script_author || current_user&.moderator?
      render_access_denied
      return
    end

    if @report.awaiting_response? && !user_is_script_author && !current_user.administrator?
      @text = 'Cannot uphold report, awaiting author response.'
      render 'home/error', status: :not_acceptable, layout: 'application'
      return
    end

    if current_user.moderator? && !@report.resolvable_by_moderator?(current_user)
      @text = 'Cannot uphold report, you are involved in this report.'
      render 'home/error', status: :not_acceptable, layout: 'application'
      return
    end

    if user_is_script_author
      @report.uphold!(moderator: nil, self_upheld: true)
    else
      @report.uphold!(
        moderator: current_user,
        moderator_notes: params[:moderator_notes],
        moderator_reason_override: params[:moderator_reason_override],
        ban_user: params[:ban] == '1' || params[:nuke].present?,
        delete_comments: params[:delete_comments] == '1' || params[:nuke].present?,
        delete_scripts: params[:delete_scripts] == '1' || params[:nuke].present?,
        redirect: params[:redirect] == '1'
      )
    end

    if @report.item.is_a?(Script) && !@report.auto_reporter
      UserNotificationService.notify_authors_for_report_resolved(@report) do |user, locale|
        ScriptReportMailer.report_upheld_offender(@report, user, locale, site_name).deliver_later
      end

      unless user_is_script_author
        UserNotificationService.notify_reporter_for_report_resolved(@report) do |user, locale|
          ScriptReportMailer.report_upheld_reporter(@report, user_is_script_author, user, locale, site_name).deliver_later
        end
      end
    end

    if user_is_script_author
      redirect_to script_path(@report.item)
    else
      redirect_to reports_path(anchor: (params[:index] == '0') ? nil : "open-report-#{params[:index]}")
    end
  end

  def rebut
    @report = Report.find(params[:id])
    unless user_is_script_author?(@report) && @report.rebuttal.nil?
      render_access_denied
      return
    end

    rebuttal = params[:report][:rebuttal]

    if rebuttal.present?
      @report.rebut!(rebuttal:, by: current_user)
      UserNotificationService.notify_reporter_for_report_rebutted(@report) do |user, locale|
        ScriptReportMailer.report_rebutted(@report, user, locale, site_name).deliver_later
      end
    end

    redirect_to report_path(@report), notice: t('reports.rebuttal_submitted')
  end

  def diff
    report = Report.find(params[:id])
    render html: helpers.report_diff(report)
  end

  private

  def report_params
    params.expect(report: [:reason, :explanation, :explanation_markup, :script_url, :discussion_category_id, { attachments: [] }])
  end

  def item
    case params[:item_class]
    when 'user'
      User.find(params[:item_id])
    when 'comment'
      Comment.find(params[:item_id])
    when 'discussion'
      Discussion.find(params[:item_id])
    when 'message'
      # Don't allow reporting a message in a conversation they're not involved in.
      Message.where(conversation: current_user.conversations).find(params[:item_id])
    when 'script'
      Script.find(params[:item_id])
    else
      render_404
    end
  end

  def user_is_script_author?(report)
    current_user && report.item.is_a?(Script) && report.item.users.include?(current_user)
  end

  def check_for_blocked_report(report = nil)
    # If the report has a history of bad reports, block reports by them for a week.
    if current_user.blocked_from_reporting_until
      render_error(200, It.it('reports.reporter_temporarily_blocked', date: I18n.l(current_user.blocked_from_reporting_until.to_date), rules_link: help_code_rules_path, site_name:))
      return true
    end

    # Allow trusted reports and mods to bypass further restrictions.
    return false if current_user.trusted_reports || current_user.moderator?

    # If lots of people have reported the item and it's always dismissed, then block reports on that item for a week.
    date = item_reporting_blocked_until
    if date
      render_error(200, It.it('reports.reported_temporarily_blocked', date: I18n.l(date.to_date), rules_link: help_code_rules_path, site_name:))
      return true
    end

    # Can't file more than one report per month for the same item (unless those reports were upheld).
    recent_report_by_same_user = Report.where(reporter: current_user, item:, result: [nil, Report::RESULT_DISMISSED], created_at: 1.month.ago..).last
    if recent_report_by_same_user
      render_error(200, It.it('reports.already_reported_by_reporter', report_link: report_path(recent_report_by_same_user)))
      return true
    end

    # Can't add another if there's a already a pending report of the same type
    if report&.reason
      previous_pending_report = Report.unresolved.where(item:).find_by(reason: report.reason)
      if previous_pending_report
        render_error(200, It.it('reports.already_reported_same_type', report_link: report_path(previous_pending_report)))
        return true
      end
    end

    false
  end

  def item_reporting_blocked_until
    recent_reports = Report.resolved.where(item:, created_at: 1.week.ago..).order(:created_at)
    recent_reports.first.created_at + 1.week if recent_reports.count(&:dismissed?) == 5
  end

  def load_report
    @report = Report.find(params[:id])
  end

  def mark_notifications_read
    Notification.unread.where(user: current_user, item: @report).mark_read!
    load_notification_count
  end
end
