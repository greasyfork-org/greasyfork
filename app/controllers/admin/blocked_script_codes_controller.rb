module Admin
  class BlockedScriptCodesController < BaseController
    before_action :administrators_only, except: :index

    def index
      @blocked_script_codes = BlockedScriptCode.order(:category, :public_reason)
    end

    def new
      @blocked_script_code = BlockedScriptCode.new
    end

    def edit
      @blocked_script_code = BlockedScriptCode.find(params[:id])
      render :new
    end

    def create
      @blocked_script_code = BlockedScriptCode.new(blocked_script_code_params)
      if @blocked_script_code.save
        redirect_to admin_blocked_script_codes_path
      else
        render :new
      end
    end

    def update
      @blocked_script_code = BlockedScriptCode.find(params[:id])
      @blocked_script_code.assign_attributes(blocked_script_code_params)
      if @blocked_script_code.save
        redirect_to admin_blocked_script_codes_path
      else
        render :new
      end
    end

    def destroy
      @blocked_script_code = BlockedScriptCode.find(params[:id])
      @blocked_script_code.destroy!
      # rubocop:disable Rails/I18nLocaleTexts
      flash[:notice] = 'Blocked Script Code deleted'
      # rubocop:enable Rails/I18nLocaleTexts
      redirect_to admin_blocked_script_codes_path
    end

    private

    def blocked_script_code_params
      params.expect(blocked_script_code: [:pattern, :public_reason, :private_reason, :result, :originating_script_id, :case_insensitive, :notify_admin, :category])
    end
  end
end
