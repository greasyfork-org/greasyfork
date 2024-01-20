module DiscussionHelper
  def render_poster(object)
    render_user(object.poster, object.poster_id, script: (object.is_a?(Discussion) || object.is_a?(Comment)) ? object.script : nil)
  end

  def discussion_snippet(discussion)
    if discussion.for_script?
      first_comment = discussion.stat_first_comment
      return first_comment ? comment_snippet(first_comment) : '(No text)'
    end

    discussion.title.truncate(200)
  end

  def comment_snippet(comment)
    format_user_text_as_plain(comment.text, comment.text_markup).truncate(200)
  end

  def scoped_comment_create_path(discussion, anchor: nil)
    if discussion.script
      script_discussion_comments_path(discussion.script, discussion, anchor:)
    else
      category_discussion_comments_path(discussion, category: discussion.discussion_category, anchor:)
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

    t(post ? 'discussions.user_activity.discussion.posted_html' : 'discussions.user_activity.discussion.replied_html', title: discussion.title)
  end

  def render_discussion_badge(key)
    text = t("discussions.badges.#{key}.short")
    title = t("discussions.badges.#{key}.long")
    tag.span(class: "badge badge-#{key}", title: (text == title) ? nil : title) { text }
  end
end
