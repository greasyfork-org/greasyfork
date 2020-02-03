require 'test_helper'
require 'timeout'

class UserTextHelperTest < ActionView::TestCase
  test "format_user_text html whitespace is formatted" do
    text = "line\nbreaks\nhere"
    assert_equal "line<br>breaks<br>here", format_user_text(text, 'html')
  end

  test "format_user_text html just whitespace" do
    text = "\n\n"
    assert_equal "<br><br>", format_user_text(text, 'html')
  end

  test "format_user_text html links are linkified" do
    text = "my url is https://example.com yes"
    assert_equal "my url is <a href=\"https://example.com\" rel=\"nofollow\">https://example.com</a> yes", format_user_text(text, 'html')
  end

  test "format_user_text html no hang on long text" do
    text = File.read(Rails.root.join(*%w(test fixtures files hamlet.txt)))
    Timeout::timeout(1) do
      format_user_text(text, 'html')
    end
  end
end
