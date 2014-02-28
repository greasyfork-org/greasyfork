class ForumDiscussion < ActiveRecord::Base
	self.table_name = 'GDN_Discussion'
	self.primary_key = 'DiscussionID'
	alias_attribute 'name', 'Name'
	
	# ignore this so we don't have to cache something we won't use
	ignore_columns :Body
	
	belongs_to :original_forum_poster, -> { readonly }, :class_name => 'ForumUser', :foreign_key => 'InsertUserID'

	def created
		return self.DateInserted
	end

	def updated
		return self.DateLastComment unless self.DateLastComment.nil?
		return self.DateInserted
	end

	def url
		"/forum/discussion/#{self.DiscussionID}/x"
	end

	def original_poster
		return original_forum_poster.user
	end

end
