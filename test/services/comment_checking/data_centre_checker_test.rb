require 'test_helper'

class DataCentreCheckerTest < ActiveSupport::TestCase
  setup do
    @comment = comments(:script_comment)
    @comment.poster.update!(created_at: 1.day.ago, current_sign_in_ip: '192.0.2.1')
    @comment.discussion.update!(rating: Discussion::RATING_BAD)
    DataCentreIps.any_instance.stubs(:data_centre?).returns(true)
  end

  def checker(comment = @comment, ip: '192.0.2.1')
    CommentChecking::DataCentreChecker.new(comment, ip:, referrer: nil, user_agent: 'Bot')
  end

  def add_review(user, rating: Discussion::RATING_BAD, script: @comment.script, at: 1.hour.ago)
    user.update!(created_at: at - 1.day, current_sign_in_ip: "192.0.2.#{user.id}")
    discussion = @comment.discussion.dup
    discussion.assign_attributes(poster: user, script:, rating:, created_at: at)
    discussion.save!
    comment = @comment.dup
    comment.assign_attributes(discussion:, poster: user, created_at: at)
    comment.save!
    comment
  end

  def add_four_reviews
    [users(:consumer), users(:junior), users(:banned), users(:mod)].map { |user| add_review(user) }
  end

  test 'flags five recent accounts rating the same script in the same direction and links the other reviews' do
    reviews = add_four_reviews
    result = checker.check

    assert_not checker.skip?
    assert result.spam?
    reviews.each { |review| assert_includes result.text, review.url }
  end

  test 'the cluster produces a moderator report without automatically banning the reviewer' do
    reviews = add_four_reviews
    (CommentCheckingService::STRATEGIES - [CommentChecking::DataCentreChecker]).each do |strategy|
      strategy.any_instance.stubs(:skip?).returns(false)
      strategy.any_instance.expects(:check).returns(CommentChecking::Result.ham(strategy.new(@comment, ip: '192.0.2.1', referrer: nil, user_agent: 'Bot')))
    end

    assert_difference -> { Report.count }, 1 do
      CommentCheckingService.check(@comment, ip: '192.0.2.1', referrer: nil, user_agent: 'Bot')
    end
    report = @comment.discussion.reports.last
    assert report.pending?
    assert_not @comment.poster.reload.banned?
    reviews.each { |review| assert_includes report.private_explanation, review.url }
    assert_equal 1, @comment.comment_check_results.spam.count
    assert_equal CommentCheckingService::STRATEGIES.size - 1, @comment.comment_check_results.ham.count
  end

  test 'does not flag fewer than five distinct reviewers' do
    add_review(users(:consumer))
    add_review(users(:consumer))
    add_review(users(:junior))
    add_review(users(:mod))
    assert_not checker.check.spam?
  end

  test 'does not count reviews outside the week, other ratings, other scripts, older accounts, or other networks' do
    reviews = add_four_reviews
    assert checker.check.spam?

    reviews[0].discussion.update_columns(created_at: @comment.discussion.created_at - 1.week - 1.second)
    assert_not checker.check.spam?
    reviews[0].discussion.update_columns(created_at: 1.hour.ago)

    reviews[1].discussion.update_columns(rating: Discussion::RATING_GOOD)
    assert_not checker.check.spam?
    reviews[1].discussion.update_columns(rating: Discussion::RATING_BAD)

    reviews[2].discussion.update_columns(script_id: scripts(:two).id)
    assert_not checker.check.spam?
    reviews[2].discussion.update_columns(script_id: @comment.script.id)

    reviews[3].poster.update!(created_at: 2.weeks.ago)
    assert_not checker.check.spam?
    reviews[3].poster.update!(created_at: 1.day.ago)

    reviews[3].poster.update!(current_sign_in_ip: nil)
    assert_not checker.check.spam?
    reviews[3].poster.update!(current_sign_in_ip: '198.51.100.1')
    DataCentreIps.any_instance.stubs(:data_centre?).with('198.51.100.1').returns(false)
    assert_not checker.check.spam?
  end

  test 'does not flag a review from outside a data centre' do
    add_four_reviews
    DataCentreIps.any_instance.stubs(:data_centre?).with('198.51.100.2').returns(false)
    assert_not checker(ip: '198.51.100.2').check.spam?
  end

  test 'does not count reviews deleted by their posters' do
    reviews = add_four_reviews
    reviews.first.discussion.soft_destroy!(by_user: reviews.first.poster)
    assert_not checker.check.spam?
  end

  test 'includes reviews and accounts exactly one week old' do
    reviews = add_four_reviews
    oldest = reviews.first
    @comment.discussion.update_columns(created_at: Time.current.change(usec: 0))
    oldest.discussion.update_columns(created_at: @comment.discussion.created_at - 1.week)
    oldest.poster.update_columns(created_at: oldest.discussion.created_at - 1.week)
    assert checker.check.spam?
  end

  test 'skips questions, replies, non-script discussions, and old accounts' do
    @comment.discussion.update!(rating: Discussion::RATING_QUESTION)
    assert checker.skip?
    assert checker(comments(:non_script_comment)).skip?
    assert checker(comments(:non_script_comment_2)).skip?
    @comment.discussion.update!(rating: Discussion::RATING_BAD)
    @comment.poster.update!(created_at: 2.weeks.ago)
    assert checker.skip?
  end
end
