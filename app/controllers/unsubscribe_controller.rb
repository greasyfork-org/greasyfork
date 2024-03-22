class UnsubscribeController < ActionController::Base
  skip_forgery_protection

  def process_one_click
    user = User.find_by_token_for(:one_click_unsubscribe, params[:token])
    unless user
      head :ok
      return
    end

    user.unsubscribe_all!
    head :ok
  end
end