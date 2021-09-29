class Conversation < ApplicationRecord
  belongs_to :stat_last_poster, class_name: 'User', optional: true

  has_many :messages, dependent: :destroy

  has_and_belongs_to_many :users, autosave: false

  attr_accessor :user_input

  accepts_nested_attributes_for :messages

  def update_stats!
    assign_stats
    save! if changed?
  end

  def assign_stats
    assign_attributes(calculate_stats)
  end

  def calculate_stats
    {
      stat_last_message_date: messages.last.created_at,
      stat_last_poster_id: messages.last.poster_id,
    }
  end

  def latest_url(user, locale: nil)
    pages = (messages.count / 50) + 1
    last_message_id = messages.order(:id).last.id
    locale = locale.code if locale.is_a?(Locale)
    Rails.application.routes.url_helpers.user_conversation_url(user, self, locale: locale || user.available_locale_code, page: pages > 1 ? pages : nil, anchor: "message-#{last_message_id}")
  end

  def latest_path(user, locale: nil)
    pages = (messages.count / 50) + 1
    last_message_id = messages.order(:id).last.id
    locale = locale.code if locale.is_a?(Locale)
    Rails.application.routes.url_helpers.user_conversation_path(user, self, locale: locale || user.available_locale_code, page: pages > 1 ? pages : nil, anchor: "message-#{last_message_id}")
  end
end
