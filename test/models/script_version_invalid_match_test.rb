require 'test_helper'

class ScriptVersionInvalidMatchTest < ActiveSupport::TestCase
  test 'non-URL in url rule' do
    sv = ScriptVersion.new
    sv.code = <<~CSS
      /* ==UserStyle==
      @name 掘金小册阅读暗黑模式
      @namespace lgldlk
      @version 0.1
      @description 掘金小册没有暗黑模式🥀，长时间阅读有点伤眼睛，于是自己做了一个✌️。
      @author lgldlk
      @license MIT
      @preprocessor default
      ==/UserStyle== */
      @-moz-document url("*://juejin.cn/book/*/section/*")
      {
        .book-content .book-content-inner .book-body {
          background-color: #4f4f4f !important ;
        }
      }
    CSS
    sv.version = '123'
    script = Script.new(language: :css)
    sv.script = script
    script.authors.build(user: User.find(1))
    sv.rewritten_code = sv.calculate_rewritten_code
    assert_not sv.valid?
    assert_equal ['Invalid matches used: url(*://juejin.cn/book/*/section/*)'], sv.errors.full_messages
  end

  test 'valid URL in url rule' do
    sv = ScriptVersion.new
    sv.code = <<~CSS
      /* ==UserStyle==
      @name 掘金小册阅读暗黑模式
      @namespace lgldlk
      @version 0.1
      @description 掘金小册没有暗黑模式🥀，长时间阅读有点伤眼睛，于是自己做了一个✌️。
      @author lgldlk
      @license MIT
      @preprocessor default
      ==/UserStyle== */
      @-moz-document url("http://juejin.cn/book/")
      {
        .book-content .book-content-inner .book-body {
          background-color: #4f4f4f !important ;
        }
      }
    CSS
    sv.version = '123'
    script = Script.new(language: :css)
    sv.script = script
    script.authors.build(user: User.find(1))
    sv.rewritten_code = sv.calculate_rewritten_code
    assert sv.valid?
  end
end
