class CpdDuplicationScript < ActiveRecord::Base
	belongs_to :cpd_duplication
	belongs_to :script
end
