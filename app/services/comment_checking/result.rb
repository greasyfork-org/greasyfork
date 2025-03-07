module CommentChecking
  class Result
    attr_accessor :spam, :text, :reports

    def initialize(spam, text: nil, reports: [])
      @spam = spam
      @text = text
      @reports = reports
    end

    def spam?
      @spam
    end

    def self.not_spam
      new(false)
    end
  end
end
