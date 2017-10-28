class SiteApplication < ApplicationRecord
  has_many :script_applies_tos
  has_many :scripts, through: :script_applies_tos
end