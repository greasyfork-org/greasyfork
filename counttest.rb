begin
  require 'bundler/inline'
rescue LoadError => e
  $stderr.puts 'Bundler version 1.10 or later is required. Please update your Bundler'
  raise e
end

gemfile(true) do
  source 'https://rubygems.org'
  gem 'rails', '7.0'
  gem 'mysql2'
end

require 'active_record'
require 'minitest/autorun'
require 'logger'

# Ensure backward compatibility with Minitest 4
Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: 'mysql2', host: 'localhost', database: 'greasyforktest', username: 'greasyforktest', password: 'password', socket: '/tmp/mysql-10.6.sock')
ActiveRecord::Base.logger = Logger.new(STDOUT)

class TestApp < Rails::Application
  config.root = __dir__
  config.load_defaults 7.0
end

ActiveRecord::Schema.define do
  create_table :posts, force: true do |t|
  end
end

class Post < ActiveRecord::Base
end

class BugTest < Minitest::Test
  def test_association_stuff
    assert_equal 0, Post.connection.select_value('select count(*) from posts')
    Post.connection.execute('insert into posts (id) values (1)')
    #Post.create!
    assert_equal 1, Post.connection.select_value('select count(*) from posts')
  end
end
