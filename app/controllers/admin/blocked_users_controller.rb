module Admin
  class BlockedUsersController < BaseController
    before_action :administrators_only, except: :index

    def index
      @blocked_users = BlockedUser.all
    end

    def new
      @blocked_user = BlockedUser.new
    end

    def edit
      @blocked_user = BlockedUser.find(params[:id])
      render :new
    end

    def create
      @blocked_user = BlockedUser.new(blocked_user_params)
      if @blocked_user.save
        redirect_to admin_blocked_users_path
      else
        render :new
      end
    end

    def update
      @blocked_user = BlockedUser.find(params[:id])
      @blocked_user.assign_attributes(blocked_user_params)
      if @blocked_user.save
        redirect_to admin_blocked_users_path
      else
        render :new
      end
    end

    def destroy
      @blocked_user = BlockedUser.find(params[:id])
      @blocked_user.destroy!
      redirect_to admin_blocked_users_path
    end

    private

    def blocked_user_params
      params.expect(blocked_user: [:pattern])
    end
  end
end
