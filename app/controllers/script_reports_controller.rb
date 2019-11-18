class ScriptReportsController < ApplicationController

  before_action :authenticate_user!, except: [:index, :show]

  before_action do
    @script = Script.find(params[:script_id])
    @bots = 'noindex'
  end

  def new
    @script_report = @script.script_reports.build(report_type: params[:report_type] || ScriptReport::TYPE_UNAUTHORIZED_CODE)
  end

  def create
    @script_report = @script.script_reports.build(script_report_create_params)
    @script_report.reporter = current_user
    if @script_report.reference_script && !@script_report.reference_script.users.include?(current_user)
      @script_report.valid?
      @script_report.errors.add(:reference_script, 'must be one of your scripts')
    elsif @script_report.script.users.include?(current_user)
      @script_report.valid?
      @script_report.errors.add(:script, 'cannot be one of your scripts')    
    elsif @script_report.save
      ScriptReportMailer.report_created(@script_report, site_name).deliver_later
      flash[:notice] = 'Your report has been recorded and will be reviewed by moderators.'
      redirect_to @script
      return
    end
    render :new
  end

  def index
  end

  def show
    @script_report = @script.script_reports.find(params[:id])
    if @script_report.unauthorized_code?
      original_code = @script_report.reference_script.script_versions.last.code
      new_code = @script_report.script.script_versions.last.code
      if original_code != new_code
        @diff = Diffy::Diff.new(original_code, new_code, include_plus_and_minus_in_html: true).to_s(:html).html_safe
      end
    end
  end

  def rebut
    is_author = @script.users.include?(current_user)
    if !is_author
      render_access_denied
      return
    end
    @script_report = @script.script_reports.find(params[:id])
    @script_report.assign_attributes(script_report_rebuttal_params)
    if @script_report.save
      ScriptReportMailer.report_rebutted(@script_report, site_name).deliver_later
      flash[:notice] = 'Your rebuttal has been recorded and will be reviewed by moderators.'
      redirect_to @script
      return
    end
    render :show
  end

  def resolve_delete
    is_author = @script.users.include?(current_user)
    if !is_author && !current_user&.moderator?
      render_access_denied
      return
    end
    @script_report = @script.script_reports.find(params[:id])
    if current_user&.moderator? && @script_report.reference_script && @script_report.reference_script.users.include?(current_user)
      # Can't delete if you are the reporter.
      render_access_denied
      return
    end
    @script_report = @script.script_reports.find(params[:id])
    @script.update(script_delete_type_id: 1, locked: true, replaced_by_script_id: @script_report.reference_script_id, delete_reason: "Deleted by #{is_author ? 'author' : 'moderator'} in response to report ##{@script_report.id}.")
    @script_report.uphold!
    ScriptReportMailer.report_upheld_reporter(@script_report, is_author, site_name).deliver_later
    ScriptReportMailer.report_upheld_offender(@script_report, site_name).deliver_later if !is_author
    @script.ban_all_authors!(moderator: current_user, reason: "In response to report #{@script_report.id}") if params[:banned]
    flash[:notice] = 'Script has been deleted.'
    redirect_to root_path
  end

  def dismiss
    @script_report = @script.script_reports.find(params[:id])
    if !current_user&.moderator?
      render_access_denied
      return
    end
    if @script_report.script.users.include?(current_user) || (@script_report.reference_script && @script_report.reference_script.users.include?(current_user))
      # Can't moderate one you're involved in.
      render_access_denied
      return
    end
    @script_report.dismiss!
    ScriptReportMailer.report_dismissed_reporter(@script_report, site_name).deliver_later
    ScriptReportMailer.report_dismissed_offender(@script_report, site_name).deliver_later
    flash[:notice] = 'Report has been dismissed.'
    redirect_to root_path
  end

  private

  def script_report_create_params
    reference = get_script_from_input(params[:script_report].delete(:reference_script))
    params[:script_report][:reference_script_id] = reference.id if reference.is_a?(Script)
    params.require(:script_report).permit(:report_type, :details, :additional_info, :reference_script_id)
  end

  def script_report_rebuttal_params
    params.require(:script_report).permit(:rebuttal)
  end

end
