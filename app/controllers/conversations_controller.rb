class ConversationsController < ApplicationController
  include BrowserCaching
  include UserTextHelper

  before_action :check_read_only_mode, except: [:show, :index]
  before_action :authenticate_user!
  before_action :find_user
  before_action :ensure_user_current, only: [:new, :create]
  before_action :find_conversation, only: [:show, :subscribe, :unsubscribe]
  before_action :disable_browser_caching!
  before_action :mark_notifications_read, only: :show

  def index
    unless @user == current_user || current_user&.administrator?
      render_404('You can only view your own conversations.')
      return
    end
    @conversations = apply_pagination(current_user.conversations.includes(:users, :stat_last_poster).order(stat_last_message_date: :desc))
  end

  def show
    @messages = apply_pagination(@conversation.messages.includes(:poster))
    @message = @conversation.messages.build(poster: current_user, content_markup: current_user&.preferred_markup)
    @subscribe = current_user.subscribed_to_conversation?(@conversation)
    @show_moderator_notice = self.class.show_moderator_notice?(current_user, @conversation.users)
  end

  def new
    @conversation = Conversation.new(user_input: params[:other_user])
    other_user = get_user_from_input(@conversation.user_input)
    @conversation.messages.build(poster: current_user, content_markup: current_user&.preferred_markup)
    @subscribe = current_user.subscribe_on_conversation_starter
    @show_moderator_notice = self.class.show_moderator_notice?(current_user, [other_user].compact)
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

    message = @conversation.messages.last
    message.poster = current_user
    message.construct_mentions(detect_possible_mentions(message.content, message.content_markup))

    unless @conversation.save
      @show_moderator_notice = self.class.show_moderator_notice?(current_user, @conversation.users)
      render :new
      return
    end

    ConversationSubscription.find_or_create_by!(user: current_user, conversation: @conversation) if @subscribe
    ConversationSubscription.find_or_create_by!(user: other_user, conversation: @conversation) if other_user.subscribe_on_conversation_receiver
    @conversation.messages.last.send_notifications!

    redirect_to user_conversation_path(current_user, @conversation)
  end

  def subscribe
    ConversationSubscription.find_or_create_by!(user: current_user, conversation: @conversation)
    respond_to do |format|
      format.js { head :ok }
      format.all { redirect_to @conversation.latest_path(current_user, locale: I18n.locale) }
    end
  end

  def unsubscribe
    ConversationSubscription.where(user: current_user, conversation: @conversation).destroy_all
    respond_to do |format|
      format.js { head :ok }
      format.all { redirect_to @conversation.latest_path(current_user, locale: I18n.locale) }
    end
  end

  def self.show_moderator_notice?(current_user, conversation_users)
    !current_user.moderator? && conversation_users.any?(&:moderator?)
  end

  private

  def find_user
    @user = User.find(params[:user_id])
  end

  def ensure_user_current
    render_404('You can only view your own conversations.') unless @user == current_user
  end

  def find_conversation
    @conversation = @user.conversations.find(params[:id])
    return if @user == current_user || (Report.unresolved.where(item: @conversation.messages).any? && current_user&.moderator?) || current_user&.administrator?

    render_404('You can only view your own conversations.')
  end

  def mark_notifications_read
    Notification.unread.where(user: current_user, item: [@conversation, @conversation.messages]).mark_read!
    load_notification_count
  end

  def conversation_params
    params.expect(conversation: [:user_input, { messages_attributes: [[:content, :content_markup, { attachments: [] }]] }])
  end
end
