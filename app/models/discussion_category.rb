class DiscussionCategory < ApplicationRecord
  has_many :discussions

  def self.script_discussions
    find_by!(category_key: 'script-discussions')
  end
end
