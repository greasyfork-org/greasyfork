require 'securerandom'

class User < ActiveRecord::Base

	has_many :scripts
	#this results in a cartesian join when included with the scripts relation
	#has_many :discussions, through: :scripts

	has_and_belongs_to_many :roles

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

	def slugify(name)
		# take out swears
		r = name.downcase.gsub(/motherfucking|motherfucker|fucking|fucker|fucks|fuck|shitty|shits|shit|niggers|nigger|cunts|cunt/, '')
		# multiple non-alphas into one
		r.gsub!(/([^[:alnum:]])[^[:alnum:]]+/) {|s| $1}
		# leading non-alphas
		r.gsub!(/^[^[:alnum:]]+/, '')
		# trailing non-alphas
		r.gsub!(/[^[:alnum:]]+$/, '')
		# non-alphas into dashes
		r.gsub!(/[^[:alnum:]]/, '-')
		# use "script" if we don't have something suitable
		r = 'user' if r.empty?
		return r
	end

	def to_param
		"#{id}-#{slugify(name)}"
	end

	def moderator?
		!roles.select { |role| role.name == 'Moderator' }.empty?
	end

	def administrator?
		!roles.select { |role| role.name == 'Moderator' }.empty?
	end

	def generate_webhook_secret
		self.webhook_secret = SecureRandom.hex(64)
	end
end
