module CommentChecking
  class Result
    attr_accessor :spam, :strategy, :text, :reports, :weight, :duplicate

    def initialize(spam, strategy:, text: nil, reports: [], weight: 1, duplicate: false)
      @spam = spam
      @text = text
      @reports = reports
      @strategy = strategy
      @weight = weight
      @duplicate = duplicate
    end

    def spam?
      @spam
    end

    def duplicate?
      @duplicate
    end

    def self.ham(strategy)
      new(false, strategy:)
    end
  end
end
