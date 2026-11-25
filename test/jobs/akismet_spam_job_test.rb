require 'test_helper'

class AkismetSpamJobTest < ActiveSupport::TestCase
  test 'submits the original checked parameters as spam' do
    params = ['127.0.0.1', 'Bot', { text: 'spam' }]
    submission = AkismetSubmission.create!(item: comments(:script_comment), akismet_params: params, result_spam: false, result_blatant: false)
    Akismet.stubs(:api_key).returns('key')
    Akismet.expects(:spam).with(*params)

    AkismetSpamJob.perform_now(submission)
  end
end
