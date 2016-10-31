class CpdDuplication < ApplicationRecord
	has_many :cpd_duplication_scripts, dependent: :destroy
end
