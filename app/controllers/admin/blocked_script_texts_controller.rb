module Admin
  class BlockedScriptTextsController < BaseController
    before_action :administrators_only, except: :index

    def index
      @blocked_script_texts = BlockedScriptText.all
    end

    def new
      @blocked_script_text = BlockedScriptText.new
    end

    def edit
      @blocked_script_text = BlockedScriptText.find(params[:id])
      render :new
    end

    def create
      @blocked_script_text = BlockedScriptText.new(blocked_script_text_params)
      if @blocked_script_text.save
        redirect_to admin_blocked_script_texts_path
      else
        render :new
      end
    end

    def update
      @blocked_script_text = BlockedScriptText.find(params[:id])
      @blocked_script_text.assign_attributes(blocked_script_text_params)
      if @blocked_script_text.save
        redirect_to admin_blocked_script_texts_path
      else
        render :new
      end
    end

    def destroy
      @blocked_script_text = BlockedScriptText.find(params[:id])
      @blocked_script_text.destroy!
      redirect_to admin_blocked_script_texts_path
    end

    private

    def blocked_script_text_params
      params.expect(blocked_script_text: [:text, :public_reason, :private_reason, :result, :notify_admin])
    end
  end
end
