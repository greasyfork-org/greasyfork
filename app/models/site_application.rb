# domain_text exists to provide a shorter, indexable column. It only has a value if the SiteApplication is for a domain.
class SiteApplication < ApplicationRecord
  self.ignored_columns += %w[domain]

  has_many :script_applies_tos, dependent: :destroy
  has_many :scripts, through: :script_applies_tos

  scope :domain, -> { where.not(domain_text: nil) }

  def domain?
    domain_text.present?
  end
end
