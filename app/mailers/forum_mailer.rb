class ForumMailer < ApplicationMailer
  include UsersHelper

  helper UsersHelper
  helper UserTextHelper

  def comment_on_script(author_user, comment)
    @comment = comment
    @site_name = 'Greasy Fork'
    @receiving_user = author_user
    set_locale_for_user(author_user, backup_locale: @comment.script.locale)
    unsubscribe_for_user(@receiving_user)

    mail(
      to: @receiving_user.email,
      subject: t('mailers.script_comment.subject',
                 script_name: @comment.script.name(@locale),
                 site_name: @site_name)
    )
  end

  def comment_on_subscribed(user, comment)
    @comment = comment
    @site_name = 'Greasy Fork'
    @receiving_user = user
    set_locale_for_user(user)
    unsubscribe_for_user(@receiving_user)

    mail(
      to: user.email,
      subject: t('mailers.subscribed_discussion.subject',
                 site_name: @site_name,
                 **localization_params_for_comment(@comment, @locale))
    )
  end

  def comment_on_mentioned(user, comment)
    @comment = comment
    @site_name = 'Greasy Fork'
    @receiving_user = user
    set_locale_for_user(user)
    unsubscribe_for_user(@receiving_user)

    mail(
      to: user.email,
      subject: t('mailers.comment_mentioned.subject',
                 site_name: @site_name,
                 **localization_params_for_comment(@comment, @locale))
    )
  end

  protected

  def localization_params_for_comment(comment, locale)
    {
      commenter_link: user_url(comment.poster_id, locale:),
      commenter_name: render_user_text(comment.poster, comment.poster_id),
      comment_link: comment.url,
      discussion_title: comment.discussion.display_title(locale:),
      discussion_link: comment.discussion.url,
    }
  end
  helper_method(:localization_params_for_comment)
end
