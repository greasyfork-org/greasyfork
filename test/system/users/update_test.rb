require 'application_system_test_case'

module Users
  class UpdateTest < ::ApplicationSystemTestCase
    test 'can update a user profile with mentions' do
      user = users(:one)
      mentioned_user = users(:geoff)

      login_as(user)
      visit user_path(user, locale: :en)
      click_link 'Edit account'
      fill_in 'Profile', with: 'My best friend is @Geoffrey'
      click_button 'Update'
      assert_selector 'h2', text: user.name
      assert_link '@Geoffrey', href: user_path(mentioned_user, locale: :en)
    end

    test 'updating username reindexes scripts' do
      user = users(:one)
      login_as(user)
      visit user_path(user, locale: :en)
      click_link 'Edit account'
      fill_in 'Name', with: 'Jerome'
      assert_reindexes do
        click_button 'Update'
        assert_selector 'h2', text: 'Jerome'
      end
    end
  end
end
