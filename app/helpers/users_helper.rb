module UsersHelper
  def user_list_link(label, sort: :unchanged, banned: :unchanged, author: :unchanged)
    current_options = {
      q: params[:q],
      sort: params[:sort],
      banned: params[:banned],
      author: params[:author],
    }.reject { |_k, v| v.nil? }

    new_options = current_options.dup

    if sort.nil?
      new_options.delete(:sort)
    elsif sort == :unchanged
      # unchanged!
    else
      new_options[:sort] = sort
    end

    if banned.nil?
      new_options.delete(:banned)
    elsif banned == :unchanged
      # unchanged!
    else
      new_options[:banned] = banned
    end

    if author.nil?
      new_options.delete(:author)
    elsif author == :unchanged
      # unchanged!
    else
      new_options[:author] = author
    end

    is_link = current_options != new_options

    text = if is_link
             link_to(label, users_path(new_options))
           else
             label
           end

    "<li class=\"list-option#{is_link ? '' : ' list-current'}\">#{text}</li>".html_safe
  end

  def render_user(user, user_id, skip_link: false, script: nil, force_author: false)
    return content_tag(:i) { 'No-one' } unless user_id
    return content_tag(:i) { "Deleted user #{user_id}" } unless user

    badge = if user.banned?
              render_badge(:banned)
            elsif force_author || script&.users&.include?(user)
              render_badge(:author)
            elsif user.moderator?
              render_badge(:moderator)
            else
              ''
            end
    if skip_link
      ''.html_safe + user.name + badge
    else
      link_to(user.name, user_path(user)) + badge
    end
  end

  def render_badge(key)
    text = t("users.badges.#{key}.short")
    title = t("users.badges.#{key}.long")
    content_tag(:span, class: "badge badge-#{key}", title: text == title ? nil : title) { text }
  end
end
