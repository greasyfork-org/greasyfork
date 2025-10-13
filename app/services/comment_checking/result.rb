module CommentChecking
  class Result
    attr_accessor :spam, :strategy, :text, :reports

    def initialize(spam, strategy:, text: nil, reports: [])
      @spam = spam
      @text = text
      @reports = reports
    end

    def spam?
      @spam
    end

    def self.not_spam(strategy)
      new(false, strategy:)
    end
  end
end
