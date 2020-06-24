require 'strip_attributes'

class DiscussionConverter
  class InvalidDiscussionException < StandardError
  end

  def self.convert(forum_discussion, raise_on_invalid: true)
    raise InvalidDiscussionException if forum_discussion.closed? || forum_discussion.rating == ForumDiscussion::RATING_REPORT

    discussion = Discussion.new(
      poster_id: forum_discussion.original_poster_id,
      created_at: forum_discussion.created,
      script: forum_discussion.script,
      rating: forum_discussion.rating,
      migrated_from: forum_discussion.id
    )

    raise InvalidDiscussionException if raise_on_invalid && !discussion.valid?

    comment = discussion.comments.build(
      poster_id: forum_discussion.original_poster_id,
      text: forum_discussion.name + "\n\n" + forum_discussion.Body,
      text_markup: get_markup(forum_discussion),
      created_at: forum_discussion.created,
      edited_at: forum_discussion.DateUpdated,
      first_comment: true
    )

    raise InvalidDiscussionException if raise_on_invalid && !comment.valid?

    forum_discussion.forum_comments.reject { |forum_comment| StripAttributes.strip_string(forum_comment.Body).nil? }.each do |forum_comment|
      discussion.comments.build(
        poster_id: forum_comment.poster_id,
        text: forum_comment.Body,
        text_markup: get_markup(forum_comment),
        created_at: forum_comment.DateInserted,
        edited_at: forum_comment.DateUpdated
      )
      raise InvalidDiscussionException if raise_on_invalid && !comment.valid?
    end

    discussion.assign_stats

    discussion
  end

  def self.get_markup(discussion_or_comment)
    format = discussion_or_comment.Format.downcase
    return format if %w[html markdown].include?(format)

    'markdown'
  end
end
