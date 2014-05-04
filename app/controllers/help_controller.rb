class HelpController < ApplicationController
	before_filter :authorize_for_moderators_only, :only => [:disallowed_code]
end
