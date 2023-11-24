class DropMostVanillaTables < ActiveRecord::Migration[7.0]
  def up
    %w(GDN_AccessToken GDN_Activity GDN_ActivityComment GDN_ActivityType GDN_AnalyticsLocal GDN_Attachment GDN_Ban GDN_Category GDN_Conversation GDN_ConversationMessage GDN_Draft GDN_Flag GDN_Invitation GDN_Log GDN_Media GDN_Message GDN_Permission GDN_Photo GDN_Regarding GDN_Role GDN_Session GDN_Spammer GDN_Tag GDN_TagDiscussion GDN_User GDN_UserAuthentication GDN_UserAuthenticationNonce GDN_UserAuthenticationProvider GDN_UserAuthenticationToken GDN_UserCategory GDN_UserComment GDN_UserConversation GDN_UserDiscussion GDN_UserIP GDN_UserMerge GDN_UserMergeItem GDN_UserMeta GDN_UserPoints GDN_UserRole GDN_contentDraft GDN_reaction GDN_reactionOwner).each do |table_name|
      drop_table table_name, if_exists: true
    end
  end
end
