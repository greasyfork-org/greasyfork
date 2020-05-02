class Comment < ApplicationRecord
  belongs_to :discussion
  belongs_to :poster, class_name: 'User'

  validates :text, presence: true
  validates :text_markup, inclusion: { in: %w[html markdown] }, presence: true
end