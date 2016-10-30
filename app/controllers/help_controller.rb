class HelpController < ApplicationController
	before_action :authorize_for_moderators_only, :only => [:disallowed_code]
end
