require 'test_helper'

class ReportTest < ActiveSupport::TestCase
  test 'move report on script discussion' do
    discussion = discussions(:script_discussion)
    category = discussion_categories(:greasyfork)
    report = Report.create!(item: discussion, reason: Report::REASON_WRONG_CATEGORY, discussion_category: category, reporter: users(:one))
    report.uphold!(moderator: users(:mod))
    assert_equal category, discussion.reload.discussion_category
  end
end
