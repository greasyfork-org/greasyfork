module UsersHelper
  def user_list_link(label, sort = nil)
    is_link = false
    if (sort.nil? && !params[:sort].blank?) || (sort.present? && sort != params[:sort])
      is_link = true
      opts = { sort: sort }
      opts[:q] = params[:q] if params[:q].present?
      label = link_to label, users_path(opts)
    end
    return ("<li class=\"list-option#{is_link ? '' : ' list-current'}\">" + label + '</li>').html_safe
  end

  def render_user(user, user_id, skip_link: false)
    return content_tag(:i) { "Deleted user #{user_id}" } unless user

    badge = if user.banned?
              content_tag(:span, class: 'badge badge-banned') { t('users.badges.banned') }
            elsif user.moderator?
              content_tag(:span, class: 'badge badge-moderator') { t('users.badges.moderator') }
            else
              ''
            end
    if skip_link
      ''.html_safe + user.name + badge
    else
      link_to(user.name, user_path(user)) + badge
    end
  end
end
