class ConversationMailer < ApplicationMailer
  include UserTextHelper

  def new_conversation(conversation, to_user, initiator_user)
    site_name = 'Greasy Fork'
    locale = to_user.available_locale_code
    mail(to: to_user.email, subject: t('mailers.new_message.subject', site_name: site_name, locale: locale, user: initiator_user.name)) do |format|
      format.text do
        render plain: t('mailers.new_message.text',
                        user: initiator_user.name,
                        conversation_url: user_conversation_url(to_user, conversation, locale: locale),
                        site_name: site_name,
                        locale: locale,
                        notification_preferences_url: notifications_user_url(to_user, locale: locale),
                        message_text: format_user_text_as_plain(conversation.messages.first.content, conversation.messages.first.content_markup, use_line_breaks: true))
      end
    end
  end

  def new_message(message, to_user)
    site_name = 'Greasy Fork'
    locale = to_user.available_locale_code
    mail(to: to_user.email, subject: t('mailers.new_message.subject', site_name: site_name, locale: locale, user: message.poster.name)) do |format|
      format.text do
        render plain: t('mailers.new_message.text',
                        user: message.poster.name,
                        site_name: site_name,
                        conversation_url: user_conversation_url(to_user, message.conversation, locale: locale, anchor: "message-#{message.id}"),
                        locale: locale,
                        notification_preferences_url: notifications_user_url(to_user, locale: locale),
                        message_text: format_user_text_as_plain(message.content, message.content_markup, use_line_breaks: true))
      end
    end
  end
end
