module Admin
  class RedirectServiceDomainsController < BaseController
    before_action :administrators_only, except: :index

    def index
      @redirect_service_domains = RedirectServiceDomain.order(:domain)
    end

    def new
      @redirect_service_domain = RedirectServiceDomain.new
    end

    def edit
      @redirect_service_domain = RedirectServiceDomain.find(params[:id])
      render :new
    end

    def create
      @redirect_service_domain = RedirectServiceDomain.new(redirect_service_domain_params)
      if @redirect_service_domain.save
        redirect_to admin_redirect_service_domains_path
      else
        render :new
      end
    end

    def update
      @redirect_service_domain = RedirectServiceDomain.find(params[:id])
      @redirect_service_domain.assign_attributes(redirect_service_domain_params)
      if @redirect_service_domain.save
        redirect_to admin_redirect_service_domains_path
      else
        render :new
      end
    end

    def destroy
      @redirect_service_domain = RedirectServiceDomain.find(params[:id])
      @redirect_service_domain.destroy!
      redirect_to admin_redirect_service_domains_path
    end

    private

    def redirect_service_domain_params
      params.expect(redirect_service_domain: [:domain])
    end
  end
end
