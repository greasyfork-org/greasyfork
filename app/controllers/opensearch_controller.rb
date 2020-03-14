class OpensearchController < ApplicationController
  def description
    render 'description', formats: :xml
  end
end
