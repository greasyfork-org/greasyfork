require 'active_support/concern'

module MentionsUsers
  extend ActiveSupport::Concern

  included do
    has_many :mentions, autosave: true, as: :mentioning_item, dependent: :destroy
  end

  def construct_mentions(possible_mentions)
    # Drop the @ and quotes
    mention_data = possible_mentions.map do |mention_text|
      bare_mention_text = mention_text.sub(/\A@/, '')
      if bare_mention_text.starts_with?('"') && bare_mention_text.ends_with?('"')
        [bare_mention_text.delete_prefix('"').delete_suffix('"'), true]
      else
        [bare_mention_text, false]
      end
    end

    # For any non-quoted mention, consider that the name might stop at a punctuation mark.
    mention_data = mention_data.map do |mention_text, with_quotes|
      texts = [mention_text]
      unless with_quotes
        while mention_text.match?(/\p{Punct}/)
          mention_text = mention_text.sub(/\p{Punct}.*\z/, '')
          texts << mention_text unless mention_text.empty?
        end
      end
      [texts, with_quotes]
    end

    possible_users = User.where(name: mention_data.map(&:first).flatten).order(Arel.sql('LENGTH(name) DESC'))

    # Associate each match with a user, or get rid of it.
    mention_data = mention_data.filter_map do |mention_texts, with_quotes|
      mentioned_user = possible_users.find { |user| mention_texts.include?(user.name) }
      next nil if mentioned_user.nil?

      [mentioned_user, with_quotes]
    end

    # Find any exact matches already in use
    existing_mentions = mentions.to_a
    existing_mentions_to_keep = []

    # See if it's an existing reference. If so, we'll leave it alone.
    mention_data = mention_data.reject do |mentioned_user, with_quotes|
      original_mention_text = with_quotes ? "@\"#{mentioned_user.name}\"" : mentioned_user.name
      existing_mention = existing_mentions.find { |m| mentioned_user.id == m.user_id && m.text == original_mention_text }
      if existing_mention
        existing_mentions_to_keep << existing_mention
        true
      else
        false
      end
    end

    # Anything no longer mentioned, marked for destruction.
    (existing_mentions - existing_mentions_to_keep).each(&:mark_for_destruction)

    # Add new ones.
    mention_data.each do |mentioned_user, with_quotes|
      original_mention_text = with_quotes ? "@\"#{mentioned_user.name}\"" : "@#{mentioned_user.name}"
      mentions.build(user: mentioned_user, text: original_mention_text)
    end
  end
end
