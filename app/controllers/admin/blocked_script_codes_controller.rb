module Admin
  class BlockedScriptCodesController < BaseController
    before_action :administrators_only, except: :index

    def index
      @blocked_script_codes = BlockedScriptCode.all
    end

    def new
      @blocked_script_code = BlockedScriptCode.new
    end

    def create
      @blocked_script_code = BlockedScriptCode.new(blocked_script_code_params)
      if @blocked_script_code.save
        redirect_to admin_blocked_script_codes_path
      else
        render :new
      end
    end

    def edit
      @blocked_script_code = BlockedScriptCode.find(params[:id])
      render :new
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
      redirect_to admin_blocked_script_codes_path
    end

    private

    def blocked_script_code_params
      params.require(:blocked_script_code).permit(:pattern, :public_reason, :private_reason, :serious, :originating_script_id)
    end
  end
end
