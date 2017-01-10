class ForumUser < ApplicationRecord
	self.table_name = 'GDN_User'
	self.primary_key = 'UserID'
	
	has_and_belongs_to_many :users, -> { readonly }, :foreign_key => 'UserID', :association_foreign_key => 'ForeignUserKey', :join_table => 'GDN_UserAuthentication'
	
	def user
		return users.first
	end
	
	# This is a read-only model, so do this in SQL.
	def rename_on_delete!
	  self.class.connection.execute "UPDATE GDN_User SET Name = 'Deleted user #{user.id}' WHERE UserID = #{id}"
	end
end
