module UsersHelper
  def user_list_link(label, sort: :unchanged, banned: :unchanged, author: :unchanged)
    current_options = {
      q: params[:q],
      sort: params[:sort],
      banned: params[:banned],
      author: params[:author],
    }.compact

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

    tag.li(class: "list-option#{is_link ? '' : ' list-current'}") { text }
  end

  def render_user_text(user, user_id)
    user&.name || "(Deleted user #{user_id})"
  end

  def render_user(user, user_id, skip_link: false, script: nil, force_author: false, skip_badge: false)
    return tag.i { 'No-one' } unless user_id
    return tag.i { "Deleted user #{user_id}" } unless user

    badge = if skip_badge
              ''
            elsif user.banned?
              render_user_badge(:banned)
            elsif force_author || script&.users&.include?(user)
              render_user_badge(:author)
            elsif user.moderator?
              render_user_badge(:moderator)
            else
              ''
            end
    if skip_link
      ''.html_safe + user.name + badge
    else
      link_to(user.name, user_path(user), class: 'user-link') + badge
    end
  end

  def render_user_badge(key)
    text = t("users.badges.#{key}.short")
    title = t("users.badges.#{key}.long")
    tag.span(class: "badge badge-#{key}", title: text == title ? nil : title) { text }
  end
end
