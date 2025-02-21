module DiscussionRestrictions
  def check_user_restrictions
    discussion_restriction = UserRestrictionService.new(current_user).discussion_restriction
    case discussion_restriction
    when nil
      # OK
    when UserRestrictionService::BLOCKED
      render 'discussions/post_blocked'
    else
      raise "Unknown restriction #{discussion_restriction}"
    end
  end
end
