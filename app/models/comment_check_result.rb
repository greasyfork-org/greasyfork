class CommentCheckResult < ApplicationRecord
  belongs_to :comment

  enum :result, { skipped: 0, not_spam: 1, spam: 2 }
end
