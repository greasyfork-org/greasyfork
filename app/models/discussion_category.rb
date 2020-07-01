class DiscussionCategory < ApplicationRecord
  has_many :discussions

  def self.script_discussions
    find_by!(category_key: 'script-discussions')
  end

  def self.non_script
    where.not(category_key: 'script-discussions')
  end
end
