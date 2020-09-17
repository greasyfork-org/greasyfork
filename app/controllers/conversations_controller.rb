class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_user
  before_action :ensure_user_current, only: [:new, :create]
  before_action :find_conversation, only: [:show, :subscribe, :unsubscribe]

  def new
    @conversation = Conversation.new(user_input: params[:other_user])
    @conversation.messages.build(poster: current_user, content_markup: current_user&.preferred_markup)
    @subscribe = current_user.subscribe_on_conversation_starter
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
    @subscribe = params[:subscribe] == '1'

    @conversation.messages.last.poster = current_user
    unless @conversation.save
      render :new
      return
    end

    ConversationSubscription.find_or_create_by!(user: current_user, conversation: @conversation) if @subscribe
    ConversationSubscription.find_or_create_by!(user: other_user, conversation: @conversation) if other_user.subscribe_on_conversation_receiver
    @conversation.messages.last.send_notifications!

    redirect_to user_conversation_path(current_user, @conversation)
  end

  def show
    @message = @conversation.messages.build(poster: current_user, content_markup: current_user&.preferred_markup)
    @subscribe = current_user.subscribed_to_conversation?(@conversation)
  end

  def index
    unless @user == current_user || current_user&.moderator?
      render_404('You can only view your own conversations.')
      return
    end
    @conversations = current_user.conversations.includes(:users, :stat_last_poster).order(stat_last_message_date: :desc).paginate(page: params[:page])
  end

  def subscribe
    ConversationSubscription.find_or_create_by!(user: current_user, conversation: @conversation)
    respond_to do |format|
      format.js { head 200 }
      format.all { redirect_to @conversation.path }
    end
  end

  def unsubscribe
    ConversationSubscription.where(user: current_user, conversation: @conversation).destroy_all
    respond_to do |format|
      format.js { head 200 }
      format.all { redirect_to @conversation.path }
    end
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
    params.require(:conversation).permit(:user_input, messages_attributes: [:content, :content_markup, { attachments: [] }])
  end
end
