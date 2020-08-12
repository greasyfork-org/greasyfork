# This file is used by Rack-based servers to start the application.

require ::File.expand_path('config/environment', __dir__)
run Rails.application

use Rack::RubyProf, path: '/www/greasyfork-profile' if Rails.env.profile?
