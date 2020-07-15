class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_user
  before_action :ensure_user_current, only: [:new, :create]
  before_action :find_conversation, only: :show

  def new
    @conversation = Conversation.new(user_input: params[:other_user])
    @conversation.messages.build(poster: current_user)
  end

  def create
    @conversation = Conversation.new(conversation_params)

    other_user = get_user_from_input(@conversation.user_input)
    if other_user.nil? || other_user == current_user
      @conversation.errors.add(:user_input, :invalid)
      render :new
      return
    end

    # Reuse an existing conversation if available.
    previous_conversation = current_user.conversations.where(id: other_user.conversations).first
    if previous_conversation
      previous_conversation.messages.build(content: @conversation.messages.first.content, content_markup: @conversation.messages.first.content_markup)
      @conversation = previous_conversation
    else
      @conversation.users = [current_user, other_user]
    end

    @conversation.messages.last.poster = current_user
    @conversation.save!
    @conversation.messages.last.send_notifications!
    redirect_to user_conversation_path(current_user, @conversation)
  end

  def show
    @message = @conversation.messages.build(poster: current_user)
  end

  private

  def find_user
    @user = User.find(params[:user_id])
  end

  def ensure_user_current
    render_404('You can only view your own conversations.') unless @user == current_user
  end

  def find_conversation
    unless @user == current_user || current_user&.moderator?
      render_404('You can only view your own conversations.')
      return
    end
    @conversation = @user.conversations.find(params[:id])
  end

  def conversation_params
    params.require(:conversation).permit(:user_input, messages_attributes: [:content, :content_markup])
  end
end