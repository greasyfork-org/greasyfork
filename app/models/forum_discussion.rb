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

  belongs_to :original_forum_poster, -> { readonly }, class_name: 'ForumUser', foreign_key: 'InsertUserID'
  belongs_to :last_reply_forum_poster, -> { readonly }, class_name: 'ForumUser', foreign_key: 'LastCommentUserID'
  belongs_to :script, foreign_key: 'ScriptID'

  has_many :forum_comments, foreign_key: 'DiscussionID'

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

  def author_posted?
    return false unless script

    forum_user_ids = script.users.map(&:forum_user).compact.map(&:UserID)
    return false if forum_user_ids.empty?

    author_posted = self.class.connection.select_value <<~SQL
      select 1
      from GDN_Comment
      where DiscussionID = #{self.DiscussionID}
        AND InsertUserID IN (#{forum_user_ids.join(',')});
    SQL

    author_posted == 1
  end

  def closed?
    self.Closed == 1
  end
end
