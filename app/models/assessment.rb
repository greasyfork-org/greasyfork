class Assessment < ActiveRecord::Base
	belongs_to :script
	belongs_to :assessment_reason

	validates_presence_of :assessment_reason
end
