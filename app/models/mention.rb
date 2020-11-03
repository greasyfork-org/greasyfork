class Mention < ApplicationRecord
  belongs_to :mentioning_item, polymorphic: true
  belongs_to :user
end
