require 'test_helper'
require 'timeout'

class UserTextHelperTest < ActionView::TestCase
  test 'format_user_text html whitespace is formatted' do
    text = "line\nbreaks\nhere"
    assert_equal '<p>line<br>breaks<br>here</p>', format_user_text(text, 'html')
  end

  test 'format_user_text html just whitespace' do
    text = "\n\n"
    assert_equal '<p><br><br></p>', format_user_text(text, 'html')
  end

  test 'format_user_text html links are linkified' do
    text = 'my url is https://example.com yes'
    assert_equal '<p>my url is <a href="https://example.com" rel="nofollow">https://example.com</a> yes</p>', format_user_text(text, 'html')
  end

  test 'format_user_text html links are linkified but without punctuation' do
    text = 'my url is https://example.com.'
    assert_equal '<p>my url is <a href="https://example.com" rel="nofollow">https://example.com</a>.</p>', format_user_text(text, 'html')
  end

  test 'format_user_text html links are linkified with trailing slashes' do
    text = 'my url is https://example.com/.'
    assert_equal '<p>my url is <a href="https://example.com/" rel="nofollow">https://example.com/</a>.</p>', format_user_text(text, 'html')
  end

  test 'format_user_text html links are linkified with dashes' do
    text = 'my url is https://example.com/some-path.'
    assert_equal '<p>my url is <a href="https://example.com/some-path" rel="nofollow">https://example.com/some-path</a>.</p>', format_user_text(text, 'html')
  end

  test 'format_user_text html links are linkified when repeated (partially)' do
    text = 'my url is https://example.com/ and https://example.com/some-path.'
    assert_equal '<p>my url is <a href="https://example.com/" rel="nofollow">https://example.com/</a> and <a href="https://example.com/some-path" rel="nofollow">https://example.com/some-path</a>.</p>', format_user_text(text, 'html')
  end

  test 'format_user_text html no hang on long text' do
    text = File.read(Rails.root.join('test/fixtures/files/hamlet.txt'))
    Timeout.timeout(1) do
      format_user_text(text, 'html')
    end
  end

  test 'format_user_text markdown paragraphs' do
    text = "p1\n\np2"
    assert_equal("<p>p1</p>\n\n<p>p2</p>\n", format_user_text(text, 'markdown'))
  end

  test 'format_user_text markdown single line uses a paragraph' do
    text = 'p1'
    assert_equal("<p>p1</p>\n", format_user_text(text, 'markdown'))
  end

  test 'format_user_text html paragraphs' do
    text = "p1\n\np2"
    assert_equal('<p>p1<br><br>p2</p>', format_user_text(text, 'html'))
  end

  test 'format_user_text html paragraphs with block inside' do
    text = "p1\n<ul><li>ul</li></ul>\np2"
    assert_equal('<p>p1</p><ul><li>ul</li></ul><p>p2</p>', format_user_text(text, 'html'))
  end

  test 'format_user_text html single line uses a paragraph' do
    text = 'p1'
    assert_equal('<p>p1</p>', format_user_text(text, 'html'))
  end

  test 'detect_possible_user_references simple' do
    user_references = detect_possible_mentions(<<~TEXT, 'markdown')
      @user1 @user2 @user1 @"user 3" @"too long to be a real user name too long to be a real user name"
    TEXT
    assert_equal ['@user1', '@user2', '@"user 3"'], user_references.to_a
  end

  test 'detect_possible_user_references start of line' do
    user_references = detect_possible_mentions('@user1 is cool', 'markdown')
    assert_equal ['@user1'], user_references.to_a
  end

  test 'detect_possible_user_references end of line' do
    user_references = detect_possible_mentions("you know who's cool? @user1", 'markdown')
    assert_equal ['@user1'], user_references.to_a
  end

  test 'detect_possible_user_references containing punctuation' do
    user_references = detect_possible_mentions("hey @user.1 - what's up?", 'markdown')
    assert_equal ['@user.1'], user_references.to_a
  end

  test 'detect_possible_user_references quoted user' do
    user_references = detect_possible_mentions('hey @"user1" - what is up?', 'markdown')
    assert_equal ['@"user1"'], user_references.to_a
  end

  test 'detect_possible_user_references quoted user with spaces' do
    user_references = detect_possible_mentions('hey @"user 1" - what is up?', 'markdown')
    assert_equal ['@"user 1"'], user_references.to_a
  end

  test 'detect_possible_user_references inside <code>' do
    user_references = detect_possible_mentions('<code>@user1</code>', 'html')
    assert_empty user_references.to_a
  end

  test 'rendering multiple mentions' do
    comment = Comment.new(text: 'There are 3 users involved here - you, @Geoffrey, and @"Timmy O\'Toole".', text_markup: 'markdown')
    comment.construct_mentions(detect_possible_mentions(comment.text, comment.text_markup))
    rendered = format_user_text(comment.text, comment.text_markup, mentions: comment.mentions)
    expected = <<~HTML
      <p>There are 3 users involved here - you, <a href="/en/users/3-geoffrey">@Geoffrey</a>, and <a href="/en/users/1-timmy-o-toole">@Timmy O'Toole</a>.</p>
    HTML
    assert_equal expected, rendered
  end

  def request_locale
    locales(:english)
  end
end
