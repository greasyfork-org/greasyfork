class CommentCheckResult < ApplicationRecord
  belongs_to :comment

  enum :result, { skipped: 0, ham: 1, spam: 2 }
end
