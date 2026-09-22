require 'test_helper'

module Discussions
  class ListingTest < ApplicationSystemTestCase
    test 'default' do
      assert_no_error_reported do
        visit discussions_path
      end
    end

    test 'sort by discussion date' do
      visit discussions_path
      click_link 'Discussion start date'
      assert_no_link 'Discussion start date'
    end

    test 'discussion search' do
      stub_es(Comment)
      assert_no_error_reported do
        visit discussions_path(q: 'test')
      end
    end
  end
end
