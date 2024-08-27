source 'https://rubygems.org'

ruby '3.3.4'

gem 'bootsnap'
gem 'csv'
gem 'daemons'
gem 'devise'
gem 'devise-i18n'
gem 'diffy'
gem 'google-analytics-data'
gem 'i18n'
gem 'mini_racer'
gem 'mysql2'
gem 'public_suffix'
gem 'puma'
gem 'puma_worker_killer'
gem 'rack-attack'
gem 'rails', '~> 7.2.0'
gem 'rails-i18n'
gem 'redcarpet'
gem 'regexp_parser'
gem 'sanitize'
# Need redis 6.2+ for sidekiq 7
gem 'sidekiq', '< 7'
gem 'sidekiq-scheduler'
gem 'sidekiq-unique-jobs'
gem 'sidekiq-worker-killer'
gem 'strip_attributes'
gem 'user_agent_parser'
gem 'vite_rails'
gem 'will_paginate'
gem 'will-paginate-i18n'

gem 'hiredis'
gem 'redis'

gem 'elasticsearch'
# For https://github.com/ankane/searchkick/commit/9b6e4ce212e77e428a065509f53c5691f42ca469, in not-yet-released 5.4.0.
gem 'searchkick', git: 'https://github.com/ankane/searchkick.git', ref: '614e5da0989d0df47043730720d42bd3cf5478e0'

gem 'stackprof'

gem 'sentry-rails'
gem 'sentry-ruby'

gem 'akismet'
gem 'detect_language'
gem 'email_address'
gem 'it'
gem 'memoist'
gem 'omniauth', '>= 1.6.0'
gem 'omniauth-github'
gem 'omniauth-gitlab'
gem 'omniauth-google-oauth2', '>= 0.4.1'
gem 'omniauth-rails_csrf_protection'

gem 'active_storage_validations'
gem 'aws-sdk-s3', require: false
gem 'image_processing'

gem 'rails-observers'
gem 'rb-readline'
gem 'recaptcha', require: 'recaptcha/rails'

group :development, :test do
  gem 'byebug'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'capistrano', '~> 3.8'
  gem 'capistrano3-puma', github: 'seuros/capistrano-puma' # Need 6.0b1 for puma 6 support
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'erb_lint', require: false
  gem 'listen'
  gem 'rubocop'
  gem 'rubocop-capybara', require: false
  gem 'rubocop-minitest', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
end

group :test do
  gem 'bundler-audit'
  gem 'capybara'
  gem 'minitest-around'
  gem 'mocha'
  gem 'selenium-webdriver'
end
