class Mention < ApplicationRecord
  belongs_to :mentioning_item, polymorphic: true
  belongs_to :user, inverse_of: 'mentions_as_target'
end
