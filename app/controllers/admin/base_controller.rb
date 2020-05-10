module Admin
  class BaseController < ApplicationController
    before_action :moderators_only
  end
end
