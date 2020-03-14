require 'application_system_test_case'

class ImportTest < ApplicationSystemTestCase
  test 'import page' do
    login_as(User.first, scope: :user)
    visit import_start_url
  end
end
