class Identity < ActiveRecord::Base

	belongs_to :user

	def pretty_provider
		Identity.pretty_provider(provider)
	end

	def self.pretty_provider(provider)
		Rails.application.config.available_auths[provider]
	end
end
