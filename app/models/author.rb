class Author < ApplicationRecord
  belongs_to :script
  belongs_to :user
end
