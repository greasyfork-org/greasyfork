require 'test_helper'

module Discussions
  class BlockedTest < ApplicationSystemTestCase
    test "new user can't post new discussion because of previous discussion pending review" do
      user = User.first
      previous_discussion = Discussion.new(poster: user, title: 'whatever', discussion_category: DiscussionCategory.first)
      previous_discussion.comments.build(text: 'whatever', poster: user)
      previous_discussion.save!
      Report.create!(item: previous_discussion, reason: Report::REASON_SPAM, reporter: User.second)
      user.update!(created_at: 1.hour.ago)

      login_as(user, scope: :user)
      visit new_discussion_path(locale: :en)
      assert_content 'Comments are blocked pending moderator review of your previous contributions. Try again later.'
    end

    test "new user can't post new discussion because of previous comment pending review" do
      user = User.first
      previous_comment = Comment.create!(discussion: Discussion.last, text: 'whatever', poster: user)
      Report.create!(item: previous_comment, reason: Report::REASON_SPAM, reporter: User.second)
      user.update!(created_at: 1.hour.ago)

      login_as(user, scope: :user)
      visit new_discussion_path(locale: :en)
      assert_content 'Comments are blocked pending moderator review of your previous contributions. Try again later.'
    end

    test 'established user has no restrictions' do
      user = User.first
      previous_discussion = Discussion.new(poster: user, title: 'whatever', discussion_category: DiscussionCategory.first)
      previous_discussion.comments.build(text: 'whatever', poster: user)
      previous_discussion.save!
      Report.create!(item: previous_discussion, reason: Report::REASON_SPAM, reporter: User.second)
      user.update!(created_at: 1.week.ago)

      login_as(user, scope: :user)
      visit new_discussion_path(locale: :en)
      assert_no_content 'Comments are blocked pending moderator review of your previous contributions. Try again later.'
      assert_content 'New discussion'
    end

    test "new user can't post new comment because of previous comment pending review" do
      user = User.first
      previous_discussion = discussions(:non_script_discussion)
      previous_comment = Comment.create!(discussion: previous_discussion, text: 'whatever', poster: user)
      Report.create!(item: previous_comment, reason: Report::REASON_SPAM, reporter: User.second)
      user.update!(created_at: 1.hour.ago)

      login_as(user, scope: :user)
      visit previous_discussion.path
      assert_content 'Comments are blocked pending moderator review of your previous contributions. Try again later.'
    end

    test "new user can't post script feedback because of previous comment pending review" do
      user = User.first
      previous_discussion = discussions(:script_discussion)
      previous_comment = Comment.create!(discussion: previous_discussion, text: 'whatever', poster: user)
      Report.create!(item: previous_comment, reason: Report::REASON_SPAM, reporter: User.second)
      user.update!(created_at: 1.hour.ago)

      login_as(user, scope: :user)
      visit feedback_script_path(previous_discussion.script, locale: :en)
      assert_content 'Comments are blocked pending moderator review of your previous contributions. Try again later.'
    end
  end
end
