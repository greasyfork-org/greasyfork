class SiteApplication < ApplicationRecord
  has_many :script_applies_tos, dependent: :destroy
  has_many :scripts, through: :script_applies_tos
end
