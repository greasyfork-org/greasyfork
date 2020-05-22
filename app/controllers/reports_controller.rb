class ReportsController < ApplicationController
  before_action :authenticate_user!, except: :show
  before_action :moderators_only, only: [:index, :dismiss, :uphold]

  before_action do
    @bots = 'noindex'
  end

  def new
    @report = Report.new(item: item, reporter: current_user)
    previous_report = Report.unresolved.where(item: item, reporter: current_user).first
    redirect_to report_path(previous_report) if previous_report
  end

  def create
    @report = Report.new(report_params)
    @report.reporter = current_user
    @report.item = item
    @report.save!
    redirect_to report_path(@report), notice: t('reports.report_filed')
  end

  def index
    @reports = Report.unresolved.reject { |report| report.item.nil? }
  end

  def dismiss
    @report = Report.find(params[:id])
    @report.dismiss!
    redirect_to reports_path
  end

  def uphold
    @report = Report.find(params[:id])
    @report.uphold!(moderator: current_user, variant: params[:variant])
    redirect_to reports_path
  end

  def show
    @report = Report.find(params[:id])
  end

  private

  def report_params
    params.require(:report).permit(:reason, :explanation)
  end

  def item
    case params[:item_class]
    when 'user'
      User.find(params[:item_id])
    when 'comment'
      Comment.find(params[:item_id])
    else
      render_404
    end
  end
end
