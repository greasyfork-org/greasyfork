class Antifeature < ApplicationRecord
  belongs_to :script
  belongs_to :locale, optional: true

  enum antifeature_type: { 'ads' => 0, 'tracking' => 1, 'miner' => 2, 'referral-link' => 3, 'membership' => 4, 'payment' => 5 }
end
