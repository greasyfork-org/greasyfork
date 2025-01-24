module Admin
  class SpammyEmailDomainsController < BaseController
    before_action :administrators_only, except: :index

    def index
      @spammy_email_domains = SpammyEmailDomain.all
    end

    def new
      @spammy_email_domain = SpammyEmailDomain.new
    end

    def edit
      @spammy_email_domain = SpammyEmailDomain.find(params[:id])
      render :new
    end

    def create
      @spammy_email_domain = SpammyEmailDomain.new(spammy_email_domain_params)
      if @spammy_email_domain.save
        redirect_to admin_spammy_email_domains_path
      else
        render :new
      end
    end

    def update
      @spammy_email_domain = SpammyEmailDomain.find(params[:id])
      @spammy_email_domain.assign_attributes(spammy_email_domain_params)
      if @spammy_email_domain.save
        redirect_to admin_spammy_email_domains_path
      else
        render :new
      end
    end

    def destroy
      @spammy_email_domain = SpammyEmailDomain.find(params[:id])
      @spammy_email_domain.destroy!
      redirect_to admin_spammy_email_domains_path
    end

    private

    def spammy_email_domain_params
      params.expect(spammy_email_domain: [:domain, :block_type])
    end
  end
end
