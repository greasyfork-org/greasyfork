module DiscussionHelper
  def render_poster(comment_or_discusion)
    render_user(comment_or_discusion.poster, comment_or_discusion.poster_id, script: comment_or_discusion.script)
  end

  def discussion_snippet(discussion)
    if discussion.for_script?
      first_comment = discussion.comments.first
      text = format_user_text_as_plain(first_comment.text, first_comment.text_markup)
    else
      text = discussion.title
    end
    text.truncate(200)
  end

  def scoped_comment_create_path(discussion)
    if discussion.script
      script_discussion_comments_path(discussion.script, discussion)
    else
      category_discussion_comments_path(discussion, category: discussion.discussion_category)
    end
  end

  def scoped_comment_path(comment)
    if comment.discussion.script
      script_discussion_comment_path(comment.discussion.script, comment.discussion, comment)
    else
      category_discussion_comment_path(comment.discussion, comment, category: comment.discussion.discussion_category)
    end
  end

  def scoped_subscribe_path(discussion)
    if discussion.script
      subscribe_script_discussion_path(discussion.script, discussion)
    else
      subscribe_category_discussion_path(discussion, category: discussion.discussion_category)
    end
  end

  def scoped_unsubscribe_path(discussion)
    if discussion.script
      unsubscribe_script_discussion_path(discussion.script, discussion)
    else
      unsubscribe_category_discussion_path(discussion, category: discussion.discussion_category)
    end
  end

  def user_activity_title(discussion, post:)
    if discussion.script
      key = if discussion.actual_rating?
              post ? 'discussions.user_activity.script_review.posted_html' : 'discussions.user_activity.script_review.replied_html'
            else
              post ? 'discussions.user_activity.script_question.posted_html' : 'discussions.user_activity.script_question.replied_html'
            end
      return t(key, script: discussion.script.name(request_locale))
    end
    raise 'not implemented'
  end
end
