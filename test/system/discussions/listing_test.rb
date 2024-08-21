require 'test_helper'

module Discussions
  class ListingTest < ApplicationSystemTestCase
    test 'default' do
      visit discussions_path
    end

    test 'sort by discussion date' do
      visit discussions_path
      click_link 'Discussion start date'
      assert_no_link 'Discussion start date'
    end
  end
end
