class ConversationMailer < ApplicationMailer
  include UsersHelper
  helper UsersHelper
  helper UserTextHelper

  def new_conversation(conversation, receiving_user, initiator_user)
    @message = conversation.messages.first
    @receiving_user = receiving_user
    @site_name = 'Greasy Fork'
    I18n.locale = @locale = @receiving_user.available_locale_code
    @conversation_url = user_conversation_url(@receiving_user, conversation, locale: @locale)
    unsubscribe_for_user(@receiving_user)

    mail(
      to: @receiving_user.email,
      subject: t('mailers.new_message.subject', site_name: @site_name, locale: @locale, user: initiator_user.name),
      template_name: 'new_message'
    )
  end

  def new_message(message, receiving_user)
    @message = message
    @receiving_user = receiving_user
    @site_name = 'Greasy Fork'
    I18n.locale = @locale = @receiving_user.available_locale_code
    @conversation_url = @message.conversation.latest_url(@receiving_user, locale: @locale)
    unsubscribe_for_user(@receiving_user)

    mail(
      to: @receiving_user.email,
      subject: t('mailers.new_message.subject', site_name: @site_name, locale: @locale, user: message.poster.name)
    )
  end
end
