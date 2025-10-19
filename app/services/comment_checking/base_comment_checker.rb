module CommentChecking
  class BaseCommentChecker
    def initialize(comment, ip:, user_agent:, referrer:)
      @comment = comment
      @ip = ip
      @user_agent = user_agent
      @referrer = referrer
    end

    def check
      raise 'Not implemented'
    end

    def skip?
      false
    end
  end
end
