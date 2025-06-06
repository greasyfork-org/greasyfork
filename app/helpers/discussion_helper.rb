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
    comment.plain_text&.truncate(200)
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

  def discussion_list_link(label, sort: :unchanged, me: :unchanged, user: :unchanged, category: :unchanged, read: :unchanged, show_locale: :unchanged, visibility: :unchanged)
    current_options = {
      q: params[:q],
      sort: params[:sort],
      me: params[:me],
      user: params[:user],
      category: params[:category],
      read: params[:read],
      show_locale: params[:show_locale],
      visibility: params[:visibility],
    }.compact

    new_options = current_options.dup

    if sort.nil?
      new_options.delete(:sort)
    elsif sort == :unchanged
      # unchanged!
    else
      new_options[:sort] = sort
    end

    if me.nil?
      new_options.delete(:me)
    elsif me == :unchanged
      # unchanged!
    else
      new_options[:me] = me
    end

    if user.nil?
      new_options.delete(:user)
    elsif user == :unchanged
      # unchanged!
    else
      new_options[:user] = user
    end

    if category.nil?
      new_options.delete(:category)
    elsif category == :unchanged
      # unchanged!
    else
      new_options[:category] = category
    end

    # Stop routing errors if they use something invalid
    new_options.delete(:category) unless %w[greasyfork development requests script-discussions no-scripts moderators].include?(new_options[:category])

    if read.nil?
      new_options.delete(:read)
    elsif read == :unchanged
      # unchanged!
    else
      new_options[:read] = read
    end

    if show_locale.nil?
      new_options.delete(:show_locale)
    elsif show_locale == :unchanged
      # unchanged!
    else
      new_options[:show_locale] = show_locale
    end

    if visibility.nil?
      new_options.delete(:visibility)
    elsif visibility == :unchanged
      # unchanged!
    else
      new_options[:visibility] = visibility
    end

    is_link = current_options != new_options

    text = if is_link
             if new_options[:category]
               link_to(label, category_discussion_index_path(new_options))
             else
               link_to(label, discussions_path(new_options))
             end
           else
             label
           end

    tag.li(class: "list-option#{' list-current' unless is_link}") { text }
  end
end
