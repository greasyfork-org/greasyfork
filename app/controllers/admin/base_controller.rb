module Admin
  class BaseController < ApplicationController
    before_action :moderators_only

    protected

    def moderators_only
      render_access_denied unless current_user&.moderator?
    end

    def administrators_only
      render_access_denied unless current_user&.administrator?
    end
  end
end
