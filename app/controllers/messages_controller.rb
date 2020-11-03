class MessagesController < ApplicationController
  include UserTextHelper

  before_action :authenticate_user!
  before_action :find_conversation

  def create
    @message = @conversation.messages.build(message_params)
    @message.poster = current_user
    @subscribe = params[:subscribe] == '1'
    @message.construct_mentions(detect_possible_mentions(@message.content, @message.content_markup))

    unless @message.save
      render 'conversations/show'
      return
    end

    if @subscribe
      ConversationSubscription.find_or_create_by!(user: current_user, conversation: @conversation)
    else
      ConversationSubscription.where(user: current_user, conversation: @conversation).destroy_all
    end
    @message.send_notifications!

    redirect_to user_conversation_path(current_user, @conversation, anchor: "message-#{@message.id}")
  end

  private

  def find_conversation
    user = User.find(params[:user_id])
    unless user == current_user
      render_404('You can only view your own conversations.')
      return
    end
    @conversation = user.conversations.find(params[:conversation_id])
  end

  def message_params
    params.require(:message).permit(:content, :content_markup, attachments: [])
  end
end
