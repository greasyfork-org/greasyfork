module CommentChecking
  class Result
    attr_accessor :spam, :strategy, :text, :reports, :weight

    def initialize(spam, strategy:, text: nil, reports: [], weight: 1)
      @spam = spam
      @text = text
      @reports = reports
      @strategy = strategy
      @weight = weight
    end

    def spam?
      @spam
    end

    def self.ham(strategy)
      new(false, strategy:)
    end
  end
end
