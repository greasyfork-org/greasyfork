class ScriptLockAppealsController < ApplicationController
  layout 'scripts', except: :index

  before_action :check_read_only_mode, except: [:show, :index]
  before_action :load_script, except: :index
  before_action :authenticate_user!, except: [:index, :show]
  before_action :load_script_lock_appeal, only: [:show, :dismiss, :unlock]
  before_action :authorize_by_script_id, only: [:new, :create]
  before_action :ensure_locked, only: [:new, :create]
  before_action :authorize_for_moderators_only, only: [:dismiss, :unlock]

  before_action do
    @bots = 'noindex,follow'
  end

  def index
    @script_lock_appeals = ScriptLockAppeal.unresolved
  end

  def show; end

  def new
    open_appeal = @script.script_lock_appeals.unresolved.first
    if open_appeal
      flash[:notice] = t('appeals.already_open')
      redirect_to script_script_lock_appeal_path(@script, open_appeal)
      return
    end

    @script_lock_appeal = @script.script_lock_appeals.build(report_id: @script.report_that_deleted&.id)
  end

  def create
    @script_lock_appeal = @script.script_lock_appeals.create!(script_lock_appeal_params)
    redirect_to script_path(@script), flash: { notice: t('appeals.submitted') }
  end

  def dismiss
    @script_lock_appeal.update!(resolution: 'dismissed', moderator_notes: params[:moderator_notes].presence)

    @script_lock_appeal.script.users.each do |user|
      ScriptLockAppealMailer.dismiss(@script_lock_appeal, user, site_name).deliver_later
    end

    redirect_to script_path(@script), flash: { notice: 'Appeal has been dismissed.' } # rubocop:disable Rails/I18nLocaleTexts
  end

  def unlock
    @script_lock_appeal.update!(resolution: 'unlocked', moderator_notes: params[:moderator_notes].presence)

    ma = ModeratorAction.new
    ma.moderator = current_user
    ma.script = @script
    ma.script_lock_appeal = @script_lock_appeal
    ma.action_taken = :undelete
    ma.save!

    @script.unlock!

    @script.script_lock_appeals.unresolved.update_all(resolution: 'unlocked')

    @script_lock_appeal.script.users.each do |user|
      ScriptLockAppealMailer.unlock(@script_lock_appeal, user, site_name).deliver_later
    end

    redirect_to script_path(@script), flash: { notice: 'Script has been unlocked.' } # rubocop:disable Rails/I18nLocaleTexts
  end

  protected

  def load_script
    @script = Script.find(params[:script_id])
  end

  def load_script_lock_appeal
    @script_lock_appeal = @script.script_lock_appeals.find(params[:id])
  end

  def ensure_locked
    render_404('Script is not locked.') unless @script.locked?
  end

  def script_lock_appeal_params
    params.expect(script_lock_appeal: [:text, :text_markup, :report_id])
  end
end
