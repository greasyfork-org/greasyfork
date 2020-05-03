class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :moderators_only, only: [:index, :dismiss, :uphold]

  def new
    @report = Report.new(item: item, reporter: current_user)
  end

  def create
    @report = Report.new(report_params)
    @report.reporter = current_user
    @report.item = item
    @report.save!
    redirect_to item, notice: t('reports.report_filed')
  end

  def index
    @reports = Report.unresolved
  end

  def dismiss
    @report = Report.find(params[:id])
    @report.dismiss!
    redirect_to reports_path
  end

  def uphold
    @report = Report.find(params[:id])
    @report.uphold!(moderator: current_user)
    redirect_to reports_path
  end

  private

  def report_params
    params.require(:report).permit(:reason, :explanation)
  end

  def item
    case params[:item_class]
    when 'user'
      User.find(params[:item_id])
    else
      render_404
    end
  end
end
