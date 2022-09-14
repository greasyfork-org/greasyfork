class Subresource < ApplicationRecord
  has_many :script_subresource_usages
  has_many :scripts, through: :script_subresource_usages
end
