class ForumUser < ActiveRecord::Base
	self.table_name = 'GDN_User'
	self.primary_key = 'UserID'
	
	has_and_belongs_to_many :users, -> { readonly }, :foreign_key => 'UserID', :association_foreign_key => 'ForeignUserKey', :join_table => 'GDN_UserAuthentication'
	
	def user
		return users.first
	end
end
