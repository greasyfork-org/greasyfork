class DiscussionCategory < ApplicationRecord
  has_many :discussions, dependent: :restrict_with_exception

  scope :visible_to_user, ->(user) { user&.moderator? ? all : where(moderators_only: false) }

  def self.script_discussions
    find_by!(category_key: 'script-discussions')
  end

  def self.non_script
    where.not(category_key: 'script-discussions')
  end

  def to_param
    category_key
  end
end
