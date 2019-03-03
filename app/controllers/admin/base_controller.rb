module Admin
  class BaseController < ApplicationController
    before_action do
      render_access_denied unless current_user&.administrator?
    end
  end
end
