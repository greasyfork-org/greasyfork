class ModeratorAction < ActiveRecord::Base

	belongs_to :script
	belongs_to :user
	belongs_to :moderator, :class_name => 'User'

	validates_presence_of :moderator, :action, :reason

	validates_length_of :action, :maximum => 50
	validates_length_of :reason, :maximum => 500

end
