class ModeratorAction < ApplicationRecord

	belongs_to :script, optional: true
	belongs_to :user, optional: true
	belongs_to :moderator, class_name: 'User'

	validates_presence_of :moderator, :action, :reason

	validates_length_of :action, :maximum => 50
	validates_length_of :reason, :maximum => 500

end
