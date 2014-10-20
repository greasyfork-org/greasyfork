require 'test_helper'

class ApplicationControllerTest < ActionController::TestCase

	test 'parse accept-language' do
		assert_equal ['da', 'en-GB', 'en'], ApplicationController.parse_accept_language('da, en-gb;q=0.8, en;q=0.7')
	end

	test 'parse accept-language no header' do
		assert_equal [], ApplicationController.parse_accept_language(nil)
	end

	test 'detect locale' do
		top, preferred = ApplicationController.detect_locale(nil, 'zu, fr-FR;q=0.8, fr;q=0.7')
		assert_equal 'fr', top.code
		assert_equal 'zu', preferred.code
	end

end
