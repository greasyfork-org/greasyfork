module Admin
  class BlockedScriptUrlsController < BaseController
    before_action :administrators_only, except: :index

    def index
      @blocked_script_urls = BlockedScriptUrl.all
    end

    def new
      @blocked_script_url = BlockedScriptUrl.new
    end

    def edit
      @blocked_script_url = BlockedScriptUrl.find(params[:id])
      render :new
    end

    def create
      @blocked_script_url = BlockedScriptUrl.new(blocked_script_url_params)
      if @blocked_script_url.save
        redirect_to admin_blocked_script_urls_path
      else
        render :new
      end
    end

    def update
      @blocked_script_url = BlockedScriptUrl.find(params[:id])
      @blocked_script_url.assign_attributes(blocked_script_url_params)
      if @blocked_script_url.save
        redirect_to admin_blocked_script_urls_path
      else
        render :new
      end
    end

    def destroy
      @blocked_script_url = BlockedScriptUrl.find(params[:id])
      @blocked_script_url.destroy!
      redirect_to admin_blocked_script_urls_path
    end

    private

    def blocked_script_url_params
      params.expect(blocked_script_url: [:url, :public_reason, :private_reason, :prefix])
    end
  end
end
