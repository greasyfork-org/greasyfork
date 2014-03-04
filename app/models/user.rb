class User < ActiveRecord::Base

	has_many :scripts
	#this results in a cartesian join when included with the scripts relation
	#has_many :discussions, through: :scripts

	# Include default devise modules. Others available are:
	# :confirmable, :lockable, :timeoutable and :omniauthable
	devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable

	validates_presence_of :name, :profile_markup
	validates_uniqueness_of :name
	validates_length_of :profile, :maximum => 10000
	validates_inclusion_of :profile_markup, :in => ['html', 'markdown']

	strip_attributes

	def discussions_on_scripts_written
		scripts.map {|s| s.discussions}.flatten.sort{|a,b| a.updated <=> b.updated }
	end
end
