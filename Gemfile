source 'https://rubygems.org'

ruby '2.6.6'

gem 'bootsnap'
gem 'daemons'
gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'devise'
gem 'devise-i18n', git: 'https://github.com/tigrish/devise-i18n.git'
gem 'diffy'
gem 'mini_racer'
gem 'mysql2'
gem 'newrelic_rpm'
gem 'public_suffix'
gem 'rails', '~> 6.0.2'
gem 'rails-i18n'
gem 'redcarpet'
gem 'sanitize'
gem 'sass-rails' # Just for the compressor
gem 'sidekiq'
gem 'strip_attributes'
gem 'thinking-sphinx'
gem 'transifex-ruby', git: 'https://github.com/tmaesaka/transifex-ruby.git'
gem 'ts-delayed-delta'
gem 'uglifier'
gem 'will-paginate-i18n'
gem 'will_paginate'

gem 'hiredis'
gem 'redis'

gem 'ace-rails-ap'
gem 'detect_language'
gem 'email_address'
# https://github.com/iGEL/it/pull/27
gem 'it', git: 'https://github.com/JasonBarnabe/it', branch: 'raise-symbol'
gem 'memoist'
gem 'omniauth', '>= 1.6.0'
gem 'omniauth-github'
gem 'omniauth-gitlab'
gem 'omniauth-google-oauth2', '>= 0.4.1'
gem 'omniauth-rails_csrf_protection'
gem 'paperclip'
gem 'rails-observers'
gem 'rb-readline'
gem 'recaptcha', require: 'recaptcha/rails'
# Rails gets support in https://github.com/rails/rails/pull/28297
gem 'rails_same_site_cookie'

source 'https://rails-assets.org' do
  gem 'rails-assets-jsonlylightbox'
end

gem 'byebug', group: [:development, :test]

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'capistrano', '~> 3.7'
  gem 'capistrano-bundler', '~> 1.2'
  gem 'capistrano-passenger'
  gem 'capistrano-rails', '~> 1.2'
  gem 'capistrano-rbenv', '~> 2.1'
  # capistrano-sidekiq 1.0.3 is marked as incompatible with Sidekiq 6, but really it is compatible, as long as you use the systemd stuff.
  gem 'capistrano-sidekiq', git: 'https://github.com/rwojnarowski/capistrano-sidekiq.git', ref: '8a8a2edf86dfcdebd69dafc4f96adc55745aecde'
  gem 'capistrano3-delayed-job', '~> 1.0'
  gem 'listen'
  gem 'rubocop'
end

group :profile do
  gem 'ruby-prof'
end

group :test do
  gem 'bundler-audit'
  gem 'capybara'
  gem 'minitest-around'
  gem 'mocha'
  gem 'selenium-webdriver'
  gem 'webdrivers', '~> 4.0'
end
