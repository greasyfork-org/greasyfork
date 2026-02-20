require 'test_helper'

class SpammyEmailDomainBannerJobTest < ActiveSupport::TestCase
  setup do
    EmailAddress.stubs(:valid?).returns(true)
  end

  test 'no matches' do
    assert_no_difference -> { SpammyEmailDomain.count } do
      SpammyEmailDomainBannerJob.perform_inline('nomatches.com')
    end
  end

  test 'matches' do
    4.times do |i|
      User.create!(email: "user#{i}@yahoo.com", banned_at: Time.zone.now, password: '12345678', password_confirmation: '12345678', name: "user#{i}")
    end
    assert_difference -> { SpammyEmailDomain.count } do
      SpammyEmailDomainBannerJob.perform_inline('yahoo.com')
    end
  end

  test 'matches but no ban if existing old user' do
    User.create!(email: 'userprime0@yahoo.com', password: '12345678', password_confirmation: '12345678', name: 'userprime0', created_at: 2.months.ago)
    4.times do |i|
      User.create!(email: "user#{i}@yahoo.com", banned_at: Time.zone.now, password: '12345678', password_confirmation: '12345678', name: "user#{i}")
    end
    assert_no_difference -> { SpammyEmailDomain.count } do
      SpammyEmailDomainBannerJob.perform_inline('yahoo.com')
    end
  end

  test 'matches with ban if existing user below threshold' do
    User.create!(email: 'userprime0@yahoo.com', password: '12345678', password_confirmation: '12345678', name: 'userprime0')
    4.times do |i|
      User.create!(email: "user#{i}@yahoo.com", banned_at: Time.zone.now, password: '12345678', password_confirmation: '12345678', name: "user#{i}")
    end
    assert_difference -> { SpammyEmailDomain.count } do
      SpammyEmailDomainBannerJob.perform_inline('yahoo.com')
    end
  end

  test 'matches with no ban if existing user above threshold' do
    User.create!(email: 'userprime0@yahoo.com', password: '12345678', password_confirmation: '12345678', name: 'userprime0')
    User.create!(email: 'userprime1@yahoo.com', password: '12345678', password_confirmation: '12345678', name: 'userprime1')
    4.times do |i|
      User.create!(email: "user#{i}@yahoo.com", banned_at: Time.zone.now, password: '12345678', password_confirmation: '12345678', name: "user#{i}")
    end
    assert_no_difference -> { SpammyEmailDomain.count } do
      SpammyEmailDomainBannerJob.perform_inline('yahoo.com')
    end
  end

  test 'matches with existing inactive ban' do
    sed = SpammyEmailDomain.create!(domain: 'yahoo.com', expires_at: 1.month.ago, block_count: 1, block_type: SpammyEmailDomain::BLOCK_TYPE_REGISTER)
    4.times do |i|
      User.create!(email: "user#{i}@yahoo.com", banned_at: Time.zone.now, password: '12345678', password_confirmation: '12345678', name: "user#{i}")
    end
    assert_no_difference -> { SpammyEmailDomain.count } do
      SpammyEmailDomainBannerJob.perform_inline('yahoo.com')
    end
    assert sed.reload.expires_at.future?
    assert sed.active?
    assert_equal 2, sed.block_count
  end
end
