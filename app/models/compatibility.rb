class Compatibility < ActiveRecord::Base
	belongs_to :script
	belongs_to :browser
end
