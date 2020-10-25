class ForumDiscussion < ApplicationRecord
  RATING_QUESTION = 0
  RATING_REPORT = 1
  RATING_BAD = 2
  RATING_OK = 3
  RATING_GOOD = 4

  self.table_name = 'GDN_Discussion'
  self.primary_key = 'DiscussionID'
  alias_attribute 'name', 'Name'
  alias_attribute 'rating', 'Rating'

  belongs_to :script, foreign_key: 'ScriptID', inverse_of: :forum_discussions

  has_many :forum_comments, foreign_key: 'DiscussionID', dependent: :restrict_with_exception, inverse_of: :forum_discussion

  scope :open, -> { where(Closed: 0) }
  scope :for_script, -> { where.not(ScriptID: nil) }

  def unescaped_name
    # Vanilla stored this as escaped. We are going to unescape on output anyway.
    return CGI.unescapeHTML(name)
  end

  def created
    return self.DateInserted
  end

  def updated
    return self.DateLastComment unless self.DateLastComment.nil?

    return self.DateInserted
  end

  def url
    "/forum/discussion/#{self.DiscussionID}/x"
  end

  def original_poster
    return original_forum_poster.user
  end

  def original_poster_id
    return original_forum_poster.user_id
  end

  def last_commenter
    return nil if last_reply_forum_poster.nil?

    return last_reply_forum_poster.user
  end

  def bad_rating?
    rating == RATING_BAD
  end

  def closed?
    self.Closed == 1
  end
end
