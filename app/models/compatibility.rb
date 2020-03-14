class Compatibility < ApplicationRecord
  belongs_to :script
  belongs_to :browser
end
