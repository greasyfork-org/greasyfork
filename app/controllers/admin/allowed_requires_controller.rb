module Admin
  class AllowedRequiresController < BaseController
    before_action :administrators_only

    def new
      @allowed_require = AllowedRequire.new
    end

    def edit
      @allowed_require = AllowedRequire.find(params[:id])
      render :new
    end

    def create
      @allowed_require = AllowedRequire.new(allowed_require_params)
      if @allowed_require.save
        redirect_to help_cdns_path
      else
        render :new
      end
    end

    def update
      @allowed_require = AllowedRequire.find(params[:id])
      @allowed_require.assign_attributes(allowed_require_params)
      if @allowed_require.save
        redirect_to help_cdns_path
      else
        render :new
      end
    end

    def destroy
      @allowed_require = AllowedRequire.find(params[:id])
      @allowed_require.destroy!
      redirect_to help_cdns_path
    end

    private

    def allowed_require_params
      params.expect(allowed_require: [:name, :url, :pattern, :comment])
    end
  end
end
