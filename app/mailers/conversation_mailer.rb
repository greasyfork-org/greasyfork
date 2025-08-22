class ConversationMailer < ApplicationMailer
  include UsersHelper

  helper UsersHelper
  helper UserTextHelper

  def new_conversation(conversation, receiving_user, initiator_user)
    # If the either user is deleted/banned, then who cares.
    return unless receiving_user && initiator_user
    return if receiving_user.banned? || initiator_user.banned?

    @message = conversation.messages.first
    @receiving_user = receiving_user
    @site_name = 'Greasy Fork'
    set_locale_for_user(@receiving_user)
    @conversation_url = user_conversation_url(@receiving_user, conversation, locale: @locale)
    unsubscribe_for_user(@receiving_user)

    mail(
      to: @receiving_user.email,
      subject: t('mailers.new_message.subject', site_name: @site_name, user: initiator_user.name),
      template_name: 'new_message'
    )
  end

  def new_message(message, receiving_user)
    # If the either user is deleted, then who cares.
    return unless receiving_user && message.poster
    return if receiving_user.banned? || message.poster.banned?

    @message = message
    @receiving_user = receiving_user
    @site_name = 'Greasy Fork'
    set_locale_for_user(@receiving_user)
    @conversation_url = @message.conversation.latest_url(@receiving_user, locale: @locale)
    unsubscribe_for_user(@receiving_user)

    mail(
      to: @receiving_user.email,
      subject: t('mailers.new_message.subject', site_name: @site_name, user: message.poster.name)
    )
  end
end
