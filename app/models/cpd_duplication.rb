class CpdDuplication < ActiveRecord::Base
	has_many :cpd_duplication_scripts, dependent: :destroy
end
