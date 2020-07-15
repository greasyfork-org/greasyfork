class Conversation < ApplicationRecord
  has_many :messages

  has_and_belongs_to_many :users, autosave: false

  attr_accessor :user_input

  accepts_nested_attributes_for :messages
end
