class HelpController < ApplicationController
  def installing_user_scripts
    @ad_method = choose_ad_method
    # All this content is on the home page.
    @bots = 'noindex'
  end
end
