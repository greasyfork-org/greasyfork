# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_11_29_210520) do

  create_table "GDN_AccessToken", primary_key: "AccessTokenID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "Token", limit: 100, null: false
    t.integer "UserID", null: false
    t.string "Type", limit: 20, null: false
    t.text "Scope"
    t.timestamp "DateInserted", default: -> { "current_timestamp()" }, null: false
    t.integer "InsertUserID"
    t.binary "InsertIPAddress", limit: 16, null: false
    t.timestamp "DateExpires", default: -> { "current_timestamp()" }, null: false
    t.text "Attributes"
    t.index ["DateExpires"], name: "IX_AccessToken_DateExpires"
    t.index ["Token"], name: "UX_AccessToken", unique: true
    t.index ["Type"], name: "IX_AccessToken_Type"
    t.index ["UserID"], name: "IX_AccessToken_UserID"
  end

  create_table "GDN_Activity", primary_key: "ActivityID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "CommentActivityID"
    t.integer "ActivityTypeID", null: false
    t.integer "NotifyUserID", default: 0, null: false
    t.integer "ActivityUserID"
    t.integer "RegardingUserID"
    t.string "Photo"
    t.string "HeadlineFormat"
    t.text "Story"
    t.string "Format", limit: 10
    t.string "Route"
    t.string "RecordType", limit: 20
    t.integer "RecordID"
    t.integer "CountComments", default: 0, null: false
    t.integer "InsertUserID"
    t.datetime "DateInserted", null: false
    t.binary "InsertIPAddress", limit: 16
    t.datetime "DateUpdated", null: false
    t.integer "Notified", limit: 1, default: 0, null: false
    t.integer "Emailed", limit: 1, default: 0, null: false
    t.text "Data"
    t.index ["CommentActivityID"], name: "FK_Activity_CommentActivityID"
    t.index ["DateUpdated"], name: "IX_Activity_DateUpdated"
    t.index ["InsertUserID"], name: "FK_Activity_InsertUserID"
    t.index ["NotifyUserID", "ActivityUserID", "DateUpdated"], name: "IX_Activity_Feed"
    t.index ["NotifyUserID", "DateUpdated"], name: "IX_Activity_Recent"
    t.index ["NotifyUserID", "Notified"], name: "IX_Activity_Notify"
  end

  create_table "GDN_ActivityComment", primary_key: "ActivityCommentID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "ActivityID", null: false
    t.text "Body", null: false
    t.string "Format", limit: 20, null: false
    t.integer "InsertUserID", null: false
    t.datetime "DateInserted", null: false
    t.binary "InsertIPAddress", limit: 16
    t.index ["ActivityID"], name: "FK_ActivityComment_ActivityID"
  end

  create_table "GDN_ActivityType", primary_key: "ActivityTypeID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "Name", limit: 20, null: false
    t.integer "AllowComments", limit: 1, default: 0, null: false
    t.integer "ShowIcon", limit: 1, default: 0, null: false
    t.string "ProfileHeadline"
    t.string "FullHeadline"
    t.string "RouteCode"
    t.integer "Notify", limit: 1, default: 0, null: false
    t.integer "Public", limit: 1, default: 1, null: false
  end

  create_table "GDN_AnalyticsLocal", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "TimeSlot", limit: 8, null: false
    t.integer "Views"
    t.integer "EmbedViews"
    t.index ["TimeSlot"], name: "UX_AnalyticsLocal", unique: true
  end

  create_table "GDN_Attachment", primary_key: "AttachmentID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "Type", limit: 64, null: false
    t.string "ForeignID", limit: 50, null: false
    t.integer "ForeignUserID", null: false
    t.string "Source", limit: 64, null: false
    t.string "SourceID", limit: 32, null: false
    t.string "SourceURL", null: false
    t.text "Attributes"
    t.datetime "DateInserted", null: false
    t.integer "InsertUserID", null: false
    t.binary "InsertIPAddress", limit: 16, null: false
    t.datetime "DateUpdated"
    t.integer "UpdateUserID"
    t.binary "UpdateIPAddress", limit: 16
    t.index ["ForeignID"], name: "IX_Attachment_ForeignID"
    t.index ["ForeignUserID"], name: "FK_Attachment_ForeignUserID"
    t.index ["InsertUserID"], name: "FK_Attachment_InsertUserID"
  end

  create_table "GDN_Ban", primary_key: "BanID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.column "BanType", "enum('IPAddress','Name','Email')", null: false
    t.string "BanValue", limit: 50, null: false
    t.string "Notes"
    t.integer "CountUsers", default: 0, null: false, unsigned: true
    t.integer "CountBlockedRegistrations", default: 0, null: false, unsigned: true
    t.integer "InsertUserID", null: false
    t.datetime "DateInserted", null: false
    t.binary "InsertIPAddress", limit: 16
    t.integer "UpdateUserID"
    t.datetime "DateUpdated"
    t.binary "UpdateIPAddress", limit: 16
    t.index ["BanType", "BanValue"], name: "UX_Ban", unique: true
  end

  create_table "GDN_Category", primary_key: "CategoryID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "ParentCategoryID"
    t.integer "TreeLeft"
    t.integer "TreeRight"
    t.integer "Depth", default: 0, null: false
    t.integer "CountCategories", default: 0, null: false
    t.integer "CountDiscussions", default: 0, null: false
    t.integer "CountAllDiscussions", default: 0, null: false
    t.integer "CountComments", default: 0, null: false
    t.integer "CountAllComments", default: 0, null: false
    t.integer "LastCategoryID", default: 0, null: false
    t.datetime "DateMarkedRead"
    t.integer "AllowDiscussions", limit: 1, default: 1, null: false
    t.integer "Archived", limit: 1, default: 0, null: false
    t.integer "CanDelete", limit: 1, default: 1, null: false
    t.string "Name", null: false
    t.string "UrlCode"
    t.string "Description", limit: 500
    t.integer "Sort"
    t.string "CssClass", limit: 50
    t.string "Photo"
    t.integer "PermissionCategoryID", default: -1, null: false
    t.integer "PointsCategoryID", default: 0, null: false
    t.integer "HideAllDiscussions", limit: 1, default: 0, null: false
    t.column "DisplayAs", "enum('Categories','Discussions','Flat','Heading','Default')", default: "Discussions", null: false
    t.integer "InsertUserID", null: false
    t.integer "UpdateUserID"
    t.datetime "DateInserted", null: false
    t.datetime "DateUpdated", null: false
    t.integer "LastCommentID"
    t.integer "LastDiscussionID"
    t.datetime "LastDateInserted"
    t.string "AllowedDiscussionTypes"
    t.string "DefaultDiscussionType", limit: 10
    t.integer "AllowFileUploads", limit: 1, default: 1, null: false
    t.index ["InsertUserID"], name: "FK_Category_InsertUserID"
    t.index ["ParentCategoryID"], name: "FK_Category_ParentCategoryID"
  end

  create_table "GDN_Comment", primary_key: "CommentID", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "DiscussionID", null: false
    t.integer "InsertUserID"
    t.integer "UpdateUserID"
    t.integer "DeleteUserID"
    t.text "Body", null: false
    t.string "Format", limit: 20
    t.datetime "DateInserted"
    t.datetime "DateDeleted"
    t.datetime "DateUpdated"
    t.binary "InsertIPAddress", limit: 16
    t.binary "UpdateIPAddress", limit: 16
    t.integer "Flag", limit: 1, default: 0, null: false
    t.float "Score"
    t.text "Attributes"
    t.index ["Body"], name: "TX_Comment", type: :fulltext
    t.index ["DateInserted"], name: "IX_Comment_DateInserted"
    t.index ["DiscussionID", "DateInserted"], name: "IX_Comment_1"
    t.index ["InsertUserID"], name: "FK_Comment_InsertUserID"
    t.index ["Score"], name: "IX_Comment_Score"
  end

  create_table "GDN_Conversation", primary_key: "ConversationID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "Type", limit: 10
    t.string "ForeignID", limit: 40
    t.string "Subject"
    t.string "Contributors"
    t.integer "FirstMessageID"
    t.integer "InsertUserID", null: false
    t.datetime "DateInserted"
    t.binary "InsertIPAddress", limit: 16
    t.integer "UpdateUserID", null: false
    t.datetime "DateUpdated", null: false
    t.binary "UpdateIPAddress", limit: 16
    t.integer "CountMessages", default: 0, null: false
    t.integer "CountParticipants", default: 0, null: false
    t.integer "LastMessageID"
    t.integer "RegardingID"
    t.index ["DateInserted"], name: "FK_Conversation_DateInserted"
    t.index ["FirstMessageID"], name: "FK_Conversation_FirstMessageID"
    t.index ["InsertUserID"], name: "FK_Conversation_InsertUserID"
    t.index ["RegardingID"], name: "IX_Conversation_RegardingID"
    t.index ["Type"], name: "IX_Conversation_Type"
    t.index ["UpdateUserID"], name: "FK_Conversation_UpdateUserID"
  end

  create_table "GDN_ConversationMessage", primary_key: "MessageID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "ConversationID", null: false
    t.text "Body", null: false
    t.string "Format", limit: 20
    t.integer "InsertUserID"
    t.datetime "DateInserted", null: false
    t.binary "InsertIPAddress", limit: 16
    t.index ["ConversationID"], name: "FK_ConversationMessage_ConversationID"
    t.index ["InsertUserID"], name: "FK_ConversationMessage_InsertUserID"
  end

  create_table "GDN_Discussion", primary_key: "DiscussionID", id: :integer, options: "ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "Type", limit: 10
    t.string "ForeignID", limit: 32
    t.integer "CategoryID", null: false
    t.integer "InsertUserID", null: false
    t.integer "UpdateUserID"
    t.integer "FirstCommentID"
    t.integer "LastCommentID"
    t.string "Name", limit: 100, null: false
    t.text "Body", null: false
    t.string "Format", limit: 20
    t.text "Tags"
    t.integer "CountComments", default: 0, null: false
    t.integer "CountBookmarks"
    t.integer "CountViews", default: 1, null: false
    t.integer "Closed", limit: 1, default: 0, null: false
    t.integer "Announce", limit: 1, default: 0, null: false
    t.integer "Sink", limit: 1, default: 0, null: false
    t.datetime "DateInserted", null: false
    t.datetime "DateUpdated"
    t.binary "InsertIPAddress", limit: 16
    t.binary "UpdateIPAddress", limit: 16
    t.datetime "DateLastComment"
    t.integer "LastCommentUserID"
    t.float "Score"
    t.text "Attributes"
    t.integer "RegardingID"
    t.integer "ScriptID"
    t.integer "Rating", default: 0, null: false
    t.index ["CategoryID", "DateInserted"], name: "IX_Discussion_CategoryInserted"
    t.index ["CategoryID", "DateLastComment"], name: "IX_Discussion_CategoryPages"
    t.index ["CategoryID"], name: "FK_Discussion_CategoryID"
    t.index ["DateInserted"], name: "IX_Discussion_DateInserted"
    t.index ["DateLastComment"], name: "IX_Discussion_DateLastComment"
    t.index ["ForeignID"], name: "IX_Discussion_ForeignID"
    t.index ["InsertUserID"], name: "FK_Discussion_InsertUserID"
    t.index ["Name", "Body"], name: "TX_Discussion", type: :fulltext
    t.index ["RegardingID"], name: "IX_Discussion_RegardingID"
    t.index ["ScriptID"], name: "index_GDN_Discussion_on_ScriptID"
    t.index ["Type"], name: "IX_Discussion_Type"
  end

  create_table "GDN_Draft", primary_key: "DraftID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "DiscussionID"
    t.integer "CategoryID"
    t.integer "InsertUserID", null: false
    t.integer "UpdateUserID", null: false
    t.string "Name", limit: 100
    t.string "Tags"
    t.integer "Closed", limit: 1, default: 0, null: false
    t.integer "Announce", limit: 1, default: 0, null: false
    t.integer "Sink", limit: 1, default: 0, null: false
    t.text "Body", null: false
    t.string "Format", limit: 20
    t.datetime "DateInserted", null: false
    t.datetime "DateUpdated"
    t.index ["CategoryID"], name: "FK_Draft_CategoryID"
    t.index ["DiscussionID"], name: "FK_Draft_DiscussionID"
    t.index ["InsertUserID"], name: "FK_Draft_InsertUserID"
  end

  create_table "GDN_Flag", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "DiscussionID"
    t.integer "InsertUserID", null: false
    t.string "InsertName", limit: 64, null: false
    t.integer "AuthorID", null: false
    t.string "AuthorName", limit: 64, null: false
    t.string "ForeignURL", limit: 191, null: false
    t.integer "ForeignID", null: false
    t.string "ForeignType", limit: 32, null: false
    t.text "Comment", null: false
    t.datetime "DateInserted", null: false
    t.index ["ForeignURL"], name: "FK_Flag_ForeignURL"
    t.index ["InsertUserID"], name: "FK_Flag_InsertUserID"
  end

  create_table "GDN_Invitation", primary_key: "InvitationID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "Email", limit: 100, null: false
    t.string "Name", limit: 50
    t.text "RoleIDs"
    t.string "Code", limit: 50, null: false
    t.integer "InsertUserID"
    t.datetime "DateInserted", null: false
    t.integer "AcceptedUserID"
    t.datetime "DateAccepted"
    t.datetime "DateExpires"
    t.index ["Code"], name: "UX_Invitation_code", unique: true
    t.index ["Email"], name: "IX_Invitation_Email"
    t.index ["InsertUserID", "DateInserted"], name: "IX_Invitation_userdate"
    t.index ["InsertUserID"], name: "FK_Invitation_InsertUserID"
  end

  create_table "GDN_Log", primary_key: "LogID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.column "Operation", "enum('Delete','Edit','Spam','Moderate','Pending','Ban','Error')", null: false
    t.column "RecordType", "enum('Discussion','Comment','User','Registration','Activity','ActivityComment','Configuration','Group','Event')", null: false
    t.integer "TransactionLogID"
    t.integer "RecordID"
    t.integer "RecordUserID"
    t.datetime "RecordDate", null: false
    t.binary "RecordIPAddress", limit: 16
    t.integer "InsertUserID", null: false
    t.datetime "DateInserted", null: false
    t.binary "InsertIPAddress", limit: 16
    t.string "OtherUserIDs"
    t.datetime "DateUpdated"
    t.integer "ParentRecordID"
    t.integer "CategoryID"
    t.text "Data", size: :medium
    t.integer "CountGroup"
    t.index ["CategoryID"], name: "FK_Log_CategoryID"
    t.index ["DateInserted"], name: "IX_Log_DateInserted"
    t.index ["Operation"], name: "IX_Log_Operation"
    t.index ["ParentRecordID"], name: "IX_Log_ParentRecordID"
    t.index ["RecordID"], name: "IX_Log_RecordID"
    t.index ["RecordIPAddress"], name: "IX_Log_RecordIPAddress"
    t.index ["RecordType"], name: "IX_Log_RecordType"
    t.index ["RecordUserID"], name: "IX_Log_RecordUserID"
  end

  create_table "GDN_Media", primary_key: "MediaID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "Name", null: false
    t.string "Type", limit: 128, null: false
    t.integer "Size", null: false
    t.integer "Active", limit: 1, default: 1, null: false
    t.integer "ImageWidth", limit: 2, unsigned: true
    t.integer "ImageHeight", limit: 2, unsigned: true
    t.integer "ThumbWidth", limit: 2, unsigned: true
    t.integer "ThumbHeight", limit: 2, unsigned: true
    t.string "ThumbPath"
    t.string "StorageMethod", limit: 24, default: "local", null: false
    t.string "Path", null: false
    t.integer "InsertUserID", null: false
    t.datetime "DateInserted", null: false
    t.integer "ForeignID"
    t.string "ForeignTable", limit: 24
    t.index ["ForeignID", "ForeignTable"], name: "IX_Media_Foreign"
    t.index ["InsertUserID"], name: "IX_Media_InsertUserID"
  end

  create_table "GDN_Message", primary_key: "MessageID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "Content", null: false
    t.string "Format", limit: 20
    t.integer "AllowDismiss", limit: 1, default: 1, null: false
    t.integer "Enabled", limit: 1, default: 1, null: false
    t.string "Application"
    t.string "Controller"
    t.string "Method"
    t.integer "CategoryID"
    t.integer "IncludeSubcategories", limit: 1, default: 0, null: false
    t.string "AssetTarget", limit: 20
    t.string "CssClass", limit: 20
    t.integer "Sort"
  end

  create_table "GDN_Permission", primary_key: "PermissionID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "RoleID", default: 0, null: false
    t.string "JunctionTable", limit: 100
    t.string "JunctionColumn", limit: 100
    t.integer "JunctionID"
    t.integer "Garden.Settings.Manage", limit: 1, default: 0, null: false
    t.integer "Garden.Settings.View", limit: 1, default: 0, null: false
    t.integer "Garden.SignIn.Allow", limit: 1, default: 0, null: false
    t.integer "Garden.Applicants.Manage", limit: 1, default: 0, null: false
    t.integer "Garden.Users.Add", limit: 1, default: 0, null: false
    t.integer "Garden.Users.Edit", limit: 1, default: 0, null: false
    t.integer "Garden.Users.Delete", limit: 1, default: 0, null: false
    t.integer "Garden.Users.Approve", limit: 1, default: 0, null: false
    t.integer "Garden.Activity.Delete", limit: 1, default: 0, null: false
    t.integer "Garden.Activity.View", limit: 1, default: 0, null: false
    t.integer "Garden.Profiles.View", limit: 1, default: 0, null: false
    t.integer "Garden.Profiles.Edit", limit: 1, default: 0, null: false
    t.integer "Garden.Moderation.Manage", limit: 1, default: 0, null: false
    t.integer "Garden.Curation.Manage", limit: 1, default: 0, null: false
    t.integer "Garden.PersonalInfo.View", limit: 1, default: 0, null: false
    t.integer "Garden.AdvancedNotifications.Allow", limit: 1, default: 0, null: false
    t.integer "Garden.Community.Manage", limit: 1, default: 0, null: false
    t.integer "Garden.Tokens.Add", limit: 1, default: 0, null: false
    t.integer "Garden.Uploads.Add", limit: 1, default: 0, null: false
    t.integer "Conversations.Moderation.Manage", limit: 1, default: 0, null: false
    t.integer "Conversations.Conversations.Add", limit: 1, default: 0, null: false
    t.integer "Vanilla.Discussions.View", limit: 1, default: 0, null: false
    t.integer "Vanilla.Discussions.Add", limit: 1, default: 0, null: false
    t.integer "Vanilla.Discussions.Edit", limit: 1, default: 0, null: false
    t.integer "Vanilla.Discussions.Announce", limit: 1, default: 0, null: false
    t.integer "Vanilla.Discussions.Sink", limit: 1, default: 0, null: false
    t.integer "Vanilla.Discussions.Close", limit: 1, default: 0, null: false
    t.integer "Vanilla.Discussions.Delete", limit: 1, default: 0, null: false
    t.integer "Vanilla.Comments.Add", limit: 1, default: 0, null: false
    t.integer "Vanilla.Comments.Edit", limit: 1, default: 0, null: false
    t.integer "Vanilla.Comments.Delete", limit: 1, default: 0, null: false
    t.integer "Plugins.Attachments.Upload.Allow", limit: 1, default: 0, null: false
    t.integer "Plugins.Attachments.Download.Allow", limit: 1, default: 0, null: false
    t.integer "Garden.Email.View", limit: 1, default: 0, null: false
    t.integer "Vanilla.Approval.Require", limit: 1, default: 0, null: false
    t.integer "Vanilla.Comments.Me", limit: 1, default: 0, null: false
    t.integer "Plugins.Flagging.Notify", limit: 1, default: 0, null: false
    t.integer "Vanilla.Tagging.Add", limit: 1, default: 0, null: false
    t.index ["RoleID"], name: "FK_Permission_RoleID"
  end

  create_table "GDN_Photo", primary_key: "PhotoID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "Name", null: false
    t.integer "InsertUserID"
    t.datetime "DateInserted", null: false
    t.index ["InsertUserID"], name: "FK_Photo_InsertUserID"
  end

  create_table "GDN_Regarding", primary_key: "RegardingID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "Type", limit: 100, null: false
    t.integer "InsertUserID", null: false
    t.datetime "DateInserted", null: false
    t.string "ForeignType", limit: 32, null: false
    t.integer "ForeignID", null: false
    t.text "OriginalContent"
    t.string "ParentType", limit: 32
    t.integer "ParentID"
    t.string "ForeignURL"
    t.text "Comment", null: false
    t.integer "Reports"
    t.index ["Type"], name: "FK_Regarding_Type"
  end

  create_table "GDN_Role", primary_key: "RoleID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "Name", limit: 100, null: false
    t.string "Description", limit: 500
    t.column "Type", "enum('guest','unconfirmed','applicant','member','moderator','administrator')"
    t.integer "Sort"
    t.integer "Deletable", limit: 1, default: 1, null: false
    t.integer "CanSession", limit: 1, default: 1, null: false
    t.integer "PersonalInfo", limit: 1, default: 0, null: false
  end

  create_table "GDN_Session", primary_key: "SessionID", id: :string, limit: 32, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "UserID", default: 0, null: false
    t.datetime "DateInserted", null: false
    t.datetime "DateUpdated"
    t.datetime "DateExpires"
    t.text "Attributes"
    t.index ["DateExpires"], name: "IX_Session_DateExpires"
  end

  create_table "GDN_Spammer", primary_key: "UserID", id: :integer, default: nil, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "CountSpam", limit: 2, default: 0, null: false, unsigned: true
    t.integer "CountDeletedSpam", limit: 2, default: 0, null: false, unsigned: true
  end

  create_table "GDN_Tag", primary_key: "TagID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "Name", limit: 100, null: false
    t.string "FullName", limit: 100, null: false
    t.string "Type", limit: 20, default: "", null: false
    t.integer "ParentTagID"
    t.integer "InsertUserID"
    t.datetime "DateInserted", null: false
    t.integer "CategoryID", default: -1, null: false
    t.integer "CountDiscussions", default: 0, null: false
    t.index ["FullName"], name: "IX_Tag_FullName"
    t.index ["InsertUserID"], name: "FK_Tag_InsertUserID"
    t.index ["Name", "CategoryID"], name: "UX_Tag", unique: true
    t.index ["ParentTagID"], name: "FK_Tag_ParentTagID"
    t.index ["Type"], name: "IX_Tag_Type"
  end

  create_table "GDN_TagDiscussion", primary_key: ["TagID", "DiscussionID"], options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "TagID", null: false
    t.integer "DiscussionID", null: false
    t.integer "CategoryID", null: false
    t.datetime "DateInserted", null: false
    t.index ["CategoryID"], name: "IX_TagDiscussion_CategoryID"
  end

  create_table "GDN_User", primary_key: "UserID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "Name", limit: 50, null: false
    t.binary "Password", limit: 100, null: false
    t.string "HashMethod", limit: 10
    t.string "Photo"
    t.string "Title", limit: 100
    t.string "Location", limit: 100
    t.text "About"
    t.string "Email", limit: 100, null: false
    t.integer "ShowEmail", limit: 1, default: 0, null: false
    t.column "Gender", "enum('u','m','f')", default: "u", null: false
    t.integer "CountVisits", default: 0, null: false
    t.integer "CountInvitations", default: 0, null: false
    t.integer "CountNotifications"
    t.integer "InviteUserID"
    t.text "DiscoveryText"
    t.text "Preferences"
    t.text "Permissions"
    t.text "Attributes"
    t.datetime "DateSetInvitations"
    t.datetime "DateOfBirth"
    t.datetime "DateFirstVisit"
    t.datetime "DateLastActive"
    t.binary "LastIPAddress", limit: 16
    t.string "AllIPAddresses", limit: 100
    t.datetime "DateInserted", null: false
    t.binary "InsertIPAddress", limit: 16
    t.datetime "DateUpdated"
    t.binary "UpdateIPAddress", limit: 16
    t.integer "HourOffset", default: 0, null: false
    t.float "Score"
    t.integer "Admin", limit: 1, default: 0, null: false
    t.integer "Confirmed", limit: 1, default: 1, null: false
    t.integer "Verified", limit: 1, default: 0, null: false
    t.integer "Banned", limit: 1, default: 0, null: false
    t.integer "Deleted", limit: 1, default: 0, null: false
    t.integer "Points", default: 0, null: false
    t.integer "CountUnreadConversations"
    t.integer "CountDiscussions"
    t.integer "CountUnreadDiscussions"
    t.integer "CountComments"
    t.integer "CountDrafts"
    t.integer "CountBookmarks"
    t.index ["DateInserted"], name: "IX_User_DateInserted"
    t.index ["DateLastActive"], name: "IX_User_DateLastActive"
    t.index ["Email"], name: "IX_User_Email"
    t.index ["Name"], name: "FK_User_Name"
  end

  create_table "GDN_UserAuthentication", primary_key: ["ForeignUserKey", "ProviderKey"], options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "ForeignUserKey", limit: 100, null: false
    t.string "ProviderKey", limit: 64, null: false
    t.integer "UserID", null: false
    t.index ["UserID"], name: "FK_UserAuthentication_UserID"
  end

  create_table "GDN_UserAuthenticationNonce", primary_key: "Nonce", id: :string, limit: 100, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "Token", limit: 128, null: false
    t.timestamp "Timestamp", default: -> { "current_timestamp()" }, null: false
    t.index ["Timestamp"], name: "IX_UserAuthenticationNonce_Timestamp"
  end

  create_table "GDN_UserAuthenticationProvider", primary_key: "AuthenticationKey", id: :string, limit: 64, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "AuthenticationSchemeAlias", limit: 32, null: false
    t.string "Name", limit: 50
    t.string "URL"
    t.text "AssociationSecret"
    t.string "AssociationHashMethod", limit: 20
    t.string "AuthenticateUrl"
    t.string "RegisterUrl"
    t.string "SignInUrl"
    t.string "SignOutUrl"
    t.string "PasswordUrl"
    t.string "ProfileUrl"
    t.text "Attributes"
    t.integer "Active", limit: 1, default: 1, null: false
    t.boolean "IsDefault", default: false, null: false
  end

  create_table "GDN_UserAuthenticationToken", primary_key: ["Token", "ProviderKey"], options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "Token", limit: 128, null: false
    t.string "ProviderKey", limit: 50, null: false
    t.string "ForeignUserKey", limit: 100
    t.string "TokenSecret", limit: 64, null: false
    t.column "TokenType", "enum('request','access')", null: false
    t.integer "Authorized", limit: 1, null: false
    t.timestamp "Timestamp", default: -> { "current_timestamp()" }, null: false
    t.integer "Lifetime", null: false
    t.index ["Timestamp"], name: "IX_UserAuthenticationToken_Timestamp"
  end

  create_table "GDN_UserCategory", primary_key: ["UserID", "CategoryID"], options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "UserID", null: false
    t.integer "CategoryID", null: false
    t.datetime "DateMarkedRead"
    t.integer "Followed", limit: 1, default: 0, null: false
    t.integer "Unfollow", limit: 1, default: 0, null: false
  end

  create_table "GDN_UserComment", primary_key: ["UserID", "CommentID"], options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "UserID", null: false
    t.integer "CommentID", null: false
    t.float "Score"
    t.datetime "DateLastViewed"
  end

  create_table "GDN_UserConversation", primary_key: ["UserID", "ConversationID"], options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "UserID", null: false
    t.integer "ConversationID", null: false
    t.integer "CountReadMessages", default: 0, null: false
    t.integer "LastMessageID"
    t.datetime "DateLastViewed"
    t.datetime "DateCleared"
    t.integer "Bookmarked", limit: 1, default: 0, null: false
    t.integer "Deleted", limit: 1, default: 0, null: false
    t.datetime "DateConversationUpdated"
    t.index ["ConversationID"], name: "FK_UserConversation_ConversationID"
    t.index ["LastMessageID"], name: "FK_UserConversation_LastMessageID"
    t.index ["UserID", "Deleted", "DateConversationUpdated"], name: "IX_UserConversation_Inbox"
  end

  create_table "GDN_UserDiscussion", primary_key: ["UserID", "DiscussionID"], options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "UserID", null: false
    t.integer "DiscussionID", null: false
    t.float "Score"
    t.integer "CountComments", default: 0, null: false
    t.datetime "DateLastViewed"
    t.integer "Dismissed", limit: 1, default: 0, null: false
    t.integer "Bookmarked", limit: 1, default: 0, null: false
    t.integer "Participated", limit: 1, default: 0, null: false
    t.index ["DiscussionID"], name: "FK_UserDiscussion_DiscussionID"
  end

  create_table "GDN_UserIP", primary_key: ["UserID", "IPAddress"], options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "UserID", null: false
    t.binary "IPAddress", limit: 16, null: false
    t.datetime "DateInserted", null: false
    t.datetime "DateUpdated", null: false
  end

  create_table "GDN_UserMerge", primary_key: "MergeID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "OldUserID", null: false
    t.integer "NewUserID", null: false
    t.datetime "DateInserted", null: false
    t.integer "InsertUserID", null: false
    t.datetime "DateUpdated"
    t.integer "UpdateUserID"
    t.text "Attributes"
    t.index ["NewUserID"], name: "FK_UserMerge_NewUserID"
    t.index ["OldUserID"], name: "FK_UserMerge_OldUserID"
  end

  create_table "GDN_UserMergeItem", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "MergeID", null: false
    t.string "Table", limit: 30, null: false
    t.string "Column", limit: 30, null: false
    t.integer "RecordID", null: false
    t.integer "OldUserID", null: false
    t.integer "NewUserID", null: false
    t.index ["MergeID"], name: "FK_UserMergeItem_MergeID"
  end

  create_table "GDN_UserMeta", primary_key: ["UserID", "Name"], options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "UserID", null: false
    t.string "Name", limit: 100, null: false
    t.text "Value"
    t.index ["Name"], name: "IX_UserMeta_Name"
  end

  create_table "GDN_UserPoints", primary_key: ["SlotType", "TimeSlot", "Source", "CategoryID", "UserID"], options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.column "SlotType", "enum('d','w','m','y','a')", null: false
    t.datetime "TimeSlot", null: false
    t.string "Source", limit: 10, default: "Total", null: false
    t.integer "CategoryID", default: 0, null: false
    t.integer "UserID", null: false
    t.integer "Points", default: 0, null: false
  end

  create_table "GDN_UserRole", primary_key: ["UserID", "RoleID"], options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "UserID", null: false
    t.integer "RoleID", null: false
    t.index ["RoleID"], name: "IX_UserRole_RoleID"
  end

  create_table "GDN_contentDraft", primary_key: "draftID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "recordType", limit: 64, null: false
    t.integer "recordID"
    t.integer "parentRecordID"
    t.text "attributes", size: :medium, null: false
    t.integer "insertUserID", null: false
    t.datetime "dateInserted", null: false
    t.integer "updateUserID", null: false
    t.datetime "dateUpdated", null: false
    t.index ["insertUserID"], name: "IX_contentDraft_insertUserID"
    t.index ["recordType", "parentRecordID"], name: "IX_contentDraft_parentRecord"
    t.index ["recordType", "recordID"], name: "IX_contentDraft_record"
    t.index ["recordType"], name: "IX_contentDraft_recordType"
  end

  create_table "GDN_reaction", primary_key: "reactionID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "reactionOwnerID", null: false
    t.integer "recordID", null: false
    t.integer "reactionValue", null: false
    t.integer "insertUserID", null: false
    t.datetime "dateInserted", null: false
    t.index ["insertUserID"], name: "IX_reaction_insertUserID"
    t.index ["reactionOwnerID", "recordID"], name: "IX_reaction_record"
    t.index ["reactionOwnerID"], name: "IX_reaction_reactionOwnerID"
  end

  create_table "GDN_reactionOwner", primary_key: "reactionOwnerID", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "ownerType", limit: 64, null: false
    t.string "reactionType", limit: 64, null: false
    t.string "recordType", limit: 64, null: false
    t.integer "insertUserID", null: false
    t.datetime "dateInserted", null: false
    t.index ["insertUserID"], name: "IX_reactionOwner_insertUserID"
    t.index ["ownerType", "reactionType", "recordType"], name: "UX_reactionOwner", unique: true
    t.index ["ownerType"], name: "IX_reactionOwner_ownerType"
    t.index ["reactionType"], name: "IX_reactionOwner_reactionType"
    t.index ["recordType"], name: "IX_reactionOwner_recordType"
  end

  create_table "active_storage_attachments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "akismet_submissions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.text "akismet_params", size: :medium, null: false
    t.boolean "result_spam", null: false
    t.boolean "result_blatant", null: false
    t.index ["item_type", "item_id"], name: "index_akismet_submissions_on_item_type_and_item_id"
  end

  create_table "allowed_requires", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "pattern", null: false
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "url", limit: 500
  end

  create_table "antifeatures", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "script_id", null: false
    t.integer "locale_id"
    t.integer "antifeature_type", null: false
    t.text "description"
    t.index ["locale_id"], name: "index_antifeatures_on_locale_id"
    t.index ["script_id"], name: "index_antifeatures_on_script_id"
  end

  create_table "author_email_notification_types", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", limit: 20, null: false
    t.string "description", limit: 100, null: false
  end

  create_table "authors", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.integer "user_id", null: false
    t.index ["script_id", "user_id"], name: "index_authors_on_script_id_and_user_id", unique: true
    t.index ["user_id"], name: "fk_rails_46e884287b"
  end

  create_table "banned_email_hashes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "email_hash", null: false
    t.datetime "deleted_at", null: false
    t.datetime "banned_at"
    t.index ["email_hash"], name: "index_banned_email_hashes_on_email_hash", unique: true
  end

  create_table "blocked_script_codes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "pattern", null: false
    t.string "public_reason", null: false
    t.string "private_reason", null: false
    t.boolean "serious", default: false, null: false
    t.integer "originating_script_id"
    t.index ["originating_script_id"], name: "fk_rails_6f37f4eb64"
  end

  create_table "blocked_script_texts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "text", null: false
    t.string "public_reason", null: false
    t.string "private_reason", null: false
    t.string "result", limit: 10, null: false
  end

  create_table "blocked_script_urls", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "url", null: false
    t.string "public_reason", null: false
    t.string "private_reason", null: false
    t.boolean "prefix", default: false, null: false
  end

  create_table "browsers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "code", limit: 20, null: false
    t.string "name", limit: 20, null: false
  end

  create_table "comments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "discussion_id", null: false
    t.integer "poster_id", null: false
    t.text "text", null: false
    t.string "text_markup", limit: 10, default: "html", null: false
    t.datetime "edited_at"
    t.boolean "first_comment", default: false, null: false
    t.datetime "deleted_at"
    t.integer "deleted_by_user_id"
    t.index ["discussion_id"], name: "index_comments_on_discussion_id"
    t.index ["poster_id"], name: "index_comments_on_poster_id"
  end

  create_table "compatibilities", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.integer "browser_id", null: false
    t.boolean "compatible", null: false
    t.string "comments", limit: 200
    t.index ["browser_id"], name: "fk_rails_d7eb310317"
    t.index ["script_id"], name: "index_compatibilities_on_script_id"
  end

  create_table "conversation_subscriptions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["conversation_id", "user_id"], name: "index_conversation_subscriptions_on_conversation_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_conversation_subscriptions_on_user_id"
  end

  create_table "conversations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "stat_last_message_date"
    t.integer "stat_last_poster_id"
  end

  create_table "conversations_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.integer "user_id", null: false
    t.index ["conversation_id"], name: "fk_rails_fa156dfe4c"
  end

  create_table "daily_install_counts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.string "ip", limit: 15, null: false
    t.timestamp "install_date", default: -> { "current_timestamp()" }, null: false
    t.index ["script_id", "ip"], name: "index_daily_install_counts_on_script_id_and_ip", unique: true
  end

  create_table "daily_update_check_counts", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.datetime "update_date", null: false
    t.string "ip", limit: 15, null: false
    t.index ["script_id", "ip"], name: "update_script_id_and_ip", unique: true
  end

  create_table "disallowed_attributes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "attribute_name", limit: 50, null: false
    t.string "pattern", null: false
    t.string "reason", null: false
    t.string "object_type", null: false
  end

  create_table "disallowed_codes", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "pattern", null: false
    t.string "description", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "originating_script_id"
    t.boolean "slow_ban", default: false, null: false
  end

  create_table "discussion_categories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "category_key", limit: 20, null: false
  end

  create_table "discussion_reads", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "discussion_id", null: false
    t.integer "user_id", null: false
    t.datetime "read_at", null: false
    t.index ["discussion_id"], name: "index_discussion_reads_on_discussion_id"
    t.index ["user_id", "discussion_id"], name: "index_discussion_reads_on_user_id_and_discussion_id", unique: true
  end

  create_table "discussion_subscriptions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "discussion_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["discussion_id", "user_id"], name: "index_discussion_subscriptions_on_discussion_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_discussion_subscriptions_on_user_id"
  end

  create_table "discussions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "poster_id", null: false
    t.integer "script_id"
    t.integer "rating"
    t.integer "stat_reply_count", default: 0, null: false
    t.datetime "stat_last_reply_date"
    t.integer "stat_last_replier_id"
    t.integer "migrated_from"
    t.integer "discussion_category_id", null: false
    t.string "title"
    t.datetime "deleted_at"
    t.integer "deleted_by_user_id"
    t.boolean "akismet_spam"
    t.boolean "akismet_blatant"
    t.string "review_reason", limit: 10
    t.index ["poster_id"], name: "index_discussions_on_poster_id"
    t.index ["script_id"], name: "fk_rails_a52537835c"
    t.index ["stat_last_reply_date"], name: "index_discussions_on_stat_last_reply_date"
  end

  create_table "identities", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "provider", limit: 20, null: false
    t.string "uid", limit: 100, null: false
    t.string "url", limit: 500
    t.boolean "syncing", null: false
    t.index ["uid", "provider"], name: "index_identities_on_uid_and_provider", unique: true
    t.index ["user_id"], name: "fk_rails_5373344100"
  end

  create_table "install_counts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.date "install_date", null: false
    t.integer "installs", null: false
    t.index ["script_id", "install_date"], name: "index_install_counts_on_script_id_and_install_date", unique: true
  end

  create_table "licenses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "code", limit: 100, null: false
    t.string "name", limit: 250, null: false
    t.string "url", limit: 250
  end

  create_table "locale_contributors", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "locale_id", null: false
    t.string "transifex_user_name", limit: 50, null: false
    t.index ["locale_id"], name: "index_locale_contributors_on_locale_id"
  end

  create_table "locales", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "code", limit: 20, null: false
    t.boolean "rtl", default: false, null: false
    t.string "detect_language_code", limit: 20
    t.string "english_name", limit: 100, null: false
    t.string "native_name", limit: 100
    t.boolean "ui_available", default: false, null: false
    t.integer "percent_complete", default: 0
  end

  create_table "localized_script_attributes", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.integer "locale_id", null: false
    t.string "attribute_key", null: false
    t.string "value_markup", null: false
    t.text "attribute_value", null: false
    t.boolean "attribute_default", null: false
    t.string "sync_identifier"
    t.integer "sync_source_id"
    t.index ["locale_id"], name: "index_localized_script_attributes_on_locale_id"
    t.index ["script_id"], name: "index_localized_script_attributes_on_script_id"
  end

  create_table "localized_script_version_attributes", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_version_id", null: false
    t.integer "locale_id", null: false
    t.string "attribute_key", null: false
    t.string "value_markup", null: false
    t.text "attribute_value", null: false
    t.boolean "attribute_default", null: false
    t.index ["locale_id"], name: "index_localized_script_version_attributes_on_locale_id"
    t.index ["script_version_id"], name: "index_localized_script_version_attributes_on_script_version_id"
  end

  create_table "mentions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "mentioning_item_type", null: false
    t.bigint "mentioning_item_id", null: false
    t.integer "user_id", null: false
    t.string "text", null: false
    t.index ["mentioning_item_type", "mentioning_item_id", "user_id"], name: "mention_mentioning"
    t.index ["user_id"], name: "fk_rails_1b711e94aa"
  end

  create_table "messages", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "conversation_id", null: false
    t.integer "poster_id", null: false
    t.string "content", limit: 10000, null: false
    t.string "content_markup", limit: 10, default: "html", null: false
    t.index ["conversation_id"], name: "fk_rails_7f927086d2"
    t.index ["poster_id"], name: "index_messages_on_poster_id"
  end

  create_table "moderator_actions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "script_id"
    t.integer "moderator_id", null: false
    t.string "action", null: false
    t.string "reason", null: false
    t.integer "user_id"
    t.string "private_reason", limit: 500
  end

  create_table "redirect_service_domains", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "domain", limit: 50, null: false
  end

  create_table "reports", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "reason", limit: 20, null: false
    t.text "explanation"
    t.integer "reporter_id"
    t.string "result", limit: 20
    t.string "auto_reporter", limit: 10
    t.index ["item_type", "item_id"], name: "index_reports_on_item_type_and_item_id"
    t.index ["reporter_id"], name: "index_reports_on_reporter_id"
    t.index ["result"], name: "index_reports_on_result"
  end

  create_table "roles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
  end

  create_table "roles_users", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "role_id", null: false
    t.index ["role_id"], name: "index_roles_users_on_role_id"
    t.index ["user_id"], name: "index_roles_users_on_user_id"
  end

  create_table "screenshots", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "screenshot_file_name"
    t.string "screenshot_content_type"
    t.integer "screenshot_file_size"
    t.datetime "screenshot_updated_at"
    t.string "caption", limit: 500
  end

  create_table "screenshots_script_versions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "screenshot_id"
    t.integer "script_version_id"
    t.index ["screenshot_id"], name: "index_screenshots_script_versions_on_screenshot_id"
    t.index ["script_version_id"], name: "index_screenshots_script_versions_on_script_version_id"
  end

  create_table "script_applies_tos", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.integer "site_application_id", null: false
    t.boolean "tld_extra", default: false, null: false
    t.index ["script_id"], name: "index_script_applies_tos_on_script_id"
  end

  create_table "script_applies_tos_bak", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.text "text", size: :medium, null: false
    t.boolean "domain", null: false
    t.boolean "tld_extra", default: false, null: false
    t.index ["script_id"], name: "index_script_applies_tos_on_script_id"
  end

  create_table "script_codes", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPRESSED", force: :cascade do |t|
    t.text "code", size: :long, null: false
    t.string "code_hash", limit: 40, null: false
    t.index ["code_hash"], name: "index_script_codes_on_code_hash"
  end

  create_table "script_delete_types", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", limit: 10, null: false
    t.string "description", limit: 500, null: false
  end

  create_table "script_invitations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.integer "invited_user_id", null: false
    t.datetime "expires_at", null: false
    t.index ["invited_user_id"], name: "fk_rails_55c05503c1"
    t.index ["script_id"], name: "fk_rails_f52d98b0ef"
  end

  create_table "script_reports", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "script_id", null: false
    t.integer "reference_script_id"
    t.text "details", null: false
    t.text "additional_info"
    t.text "rebuttal"
    t.string "report_type", limit: 20, null: false
    t.integer "reporter_id"
    t.string "result", limit: 10
    t.text "moderator_note"
    t.string "auto_reporter", limit: 10
    t.index ["reference_script_id"], name: "index_script_reports_on_reference_script_id"
    t.index ["reporter_id"], name: "fk_rails_8cb0f3e455"
    t.index ["script_id"], name: "index_script_reports_on_script_id"
  end

  create_table "script_set_automatic_set_inclusions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "parent_id", null: false
    t.integer "script_set_automatic_type_id", null: false
    t.string "value", limit: 100
    t.boolean "exclusion", default: false, null: false
    t.index ["parent_id"], name: "index_script_set_automatic_set_inclusions_on_parent_id"
    t.index ["script_set_automatic_type_id"], name: "ssasi_script_set_automatic_type_id"
  end

  create_table "script_set_automatic_types", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", limit: 50, null: false
  end

  create_table "script_set_script_inclusions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "parent_id", null: false
    t.integer "child_id", null: false
    t.boolean "exclusion", default: false, null: false
    t.index ["child_id"], name: "index_script_set_script_inclusions_on_child_id"
    t.index ["parent_id"], name: "index_script_set_script_inclusions_on_parent_id"
  end

  create_table "script_set_set_inclusions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "parent_id", null: false
    t.integer "child_id", null: false
    t.boolean "exclusion", default: false, null: false
    t.index ["child_id"], name: "index_script_set_set_inclusions_on_child_id"
    t.index ["parent_id"], name: "index_script_set_set_inclusions_on_parent_id"
  end

  create_table "script_sets", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", limit: 100, null: false
    t.text "description", size: :medium, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "favorite", default: false, null: false
    t.string "default_sort", limit: 20
    t.index ["user_id"], name: "index_script_sets_on_user_id"
  end

  create_table "script_similarities", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.integer "other_script_id", null: false
    t.decimal "similarity", precision: 4, scale: 3, null: false
    t.datetime "checked_at", null: false
    t.index ["other_script_id"], name: "fk_rails_3fba862a5b"
    t.index ["script_id", "other_script_id"], name: "index_script_similarities_on_script_id_and_other_script_id", unique: true
  end

  create_table "script_sync_sources", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "description", null: false
  end

  create_table "script_sync_types", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "description", null: false
  end

  create_table "script_types", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "description", null: false
    t.string "short_name", limit: 10
  end

  create_table "script_versions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.text "changelog", size: :medium
    t.string "changelog_markup", limit: 10, default: "text", null: false
    t.string "version", limit: 200, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "script_code_id", null: false
    t.integer "rewritten_script_code_id", null: false
    t.boolean "not_js_convertible_override", default: false, null: false
    t.index ["rewritten_script_code_id"], name: "index_script_versions_on_rewritten_script_code_id"
    t.index ["script_code_id"], name: "index_script_versions_on_script_code_id"
    t.index ["script_id"], name: "index_script_versions_on_script_id"
  end

  create_table "scripts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "daily_installs", default: 0, null: false
    t.integer "total_installs", default: 0, null: false
    t.datetime "code_updated_at", null: false
    t.integer "script_type_id", default: 1, null: false
    t.integer "script_sync_type_id"
    t.integer "script_sync_source_id"
    t.string "sync_identifier", limit: 500
    t.string "sync_error", limit: 1000
    t.datetime "last_attempted_sync_date"
    t.datetime "last_successful_sync_date"
    t.boolean "delta", default: true, null: false
    t.string "license_text", limit: 500
    t.integer "license_id"
    t.integer "script_delete_type_id"
    t.boolean "locked", default: false, null: false
    t.string "support_url", limit: 500
    t.integer "locale_id"
    t.decimal "fan_score", precision: 3, scale: 1, default: "0.0", null: false
    t.string "namespace", limit: 500
    t.string "delete_reason"
    t.string "contribution_url"
    t.string "contribution_amount"
    t.string "default_name", null: false
    t.integer "good_ratings", default: 0
    t.integer "ok_ratings", default: 0
    t.integer "bad_ratings", default: 0
    t.integer "replaced_by_script_id"
    t.string "version", limit: 200, null: false
    t.boolean "sensitive", default: false, null: false
    t.datetime "not_adult_content_self_report_date"
    t.datetime "permanent_deletion_request_date"
    t.boolean "promoted", default: false, null: false
    t.integer "promoted_script_id"
    t.boolean "adsense_approved"
    t.integer "page_views", default: 0, null: false
    t.boolean "has_syntax_error", default: false, null: false
    t.string "language", limit: 3, default: "js", null: false
    t.boolean "css_convertible_to_js", default: false, null: false
    t.boolean "not_js_convertible_override", default: false, null: false
    t.string "review_state", default: "not_required", null: false
    t.datetime "deleted_at"
    t.datetime "consecutive_bad_ratings_at"
    t.integer "marked_adult_by_user_id"
    t.index ["delta"], name: "index_scripts_on_delta"
    t.index ["promoted"], name: "index_scripts_on_promoted"
    t.index ["promoted_script_id"], name: "fk_rails_f98f8b875c"
    t.index ["review_state"], name: "index_scripts_on_review_state"
    t.index ["script_delete_type_id"], name: "index_scripts_on_script_delete_type_id"
    t.index ["script_type_id"], name: "index_scripts_on_script_type_id"
  end

  create_table "sensitive_sites", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "domain", limit: 150, null: false
    t.index ["domain"], name: "index_sensitive_sites_on_domain", unique: true
  end

  create_table "site_applications", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "text", null: false
    t.boolean "domain", null: false
    t.boolean "blocked", default: false, null: false
    t.string "blocked_message"
  end

  create_table "spammy_email_domains", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "domain", limit: 20, null: false
    t.string "block_type", limit: 20, null: false
    t.index ["domain"], name: "index_spammy_email_domains_on_domain"
  end

  create_table "syntax_highlighted_codes", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.text "html", size: :medium, null: false
    t.index ["script_id"], name: "index_syntax_highlighted_codes_on_script_id"
  end

  create_table "test_update_counts", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.datetime "update_date", null: false
    t.string "ip", limit: 15, null: false
    t.index ["script_id", "ip"], name: "update_script_id_and_ip", unique: true
  end

  create_table "update_check_counts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.date "update_check_date", null: false
    t.integer "update_checks", null: false
    t.index ["script_id", "update_check_date"], name: "index_update_check_counts_on_script_id_and_update_check_date", unique: true
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "email", limit: 150, default: "", null: false
    t.string "encrypted_password", default: ""
    t.string "reset_password_token", limit: 150
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name", limit: 50, null: false
    t.string "profile", limit: 10000
    t.string "profile_markup", limit: 10, default: "html", null: false
    t.string "webhook_secret", limit: 128
    t.integer "author_email_notification_type_id", default: 1, null: false
    t.string "remember_token", limit: 150
    t.integer "locale_id"
    t.boolean "show_ads", default: true, null: false
    t.string "preferred_markup", limit: 10, default: "html", null: false
    t.boolean "show_sensitive", default: false
    t.string "delete_confirmation_key"
    t.datetime "delete_confirmation_expiry"
    t.string "confirmation_token", limit: 50
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.boolean "disposable_email"
    t.boolean "trusted_reports", default: false, null: false
    t.string "announcements_seen"
    t.string "canonical_email", null: false
    t.datetime "discussions_read_since"
    t.boolean "subscribe_on_discussion", default: true, null: false
    t.boolean "subscribe_on_comment", default: true, null: false
    t.boolean "subscribe_on_conversation_starter", default: true, null: false
    t.boolean "subscribe_on_conversation_receiver", default: true, null: false
    t.datetime "banned_at"
    t.string "email_domain", limit: 100
    t.string "session_token", limit: 32
    t.boolean "filter_locale_default", default: true, null: false
    t.boolean "notify_on_mention", default: false, null: false
    t.index ["canonical_email"], name: "index_users_on_canonical_email"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["email_domain", "current_sign_in_ip", "banned_at"], name: "index_users_on_email_domain_and_current_sign_in_ip_and_banned_at"
    t.index ["name"], name: "index_users_on_name", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "antifeatures", "locales"
  add_foreign_key "antifeatures", "scripts", on_delete: :cascade
  add_foreign_key "authors", "scripts", on_delete: :cascade
  add_foreign_key "authors", "users", on_delete: :cascade
  add_foreign_key "blocked_script_codes", "scripts", column: "originating_script_id", on_delete: :cascade
  add_foreign_key "comments", "discussions", on_delete: :cascade
  add_foreign_key "compatibilities", "browsers", on_delete: :cascade
  add_foreign_key "compatibilities", "scripts", on_delete: :cascade
  add_foreign_key "conversation_subscriptions", "conversations", on_delete: :cascade
  add_foreign_key "conversation_subscriptions", "users", on_delete: :cascade
  add_foreign_key "conversations_users", "conversations", on_delete: :cascade
  add_foreign_key "discussion_reads", "discussions", on_delete: :cascade
  add_foreign_key "discussion_reads", "users", on_delete: :cascade
  add_foreign_key "discussion_subscriptions", "discussions", on_delete: :cascade
  add_foreign_key "discussion_subscriptions", "users", on_delete: :cascade
  add_foreign_key "discussions", "scripts", on_delete: :cascade
  add_foreign_key "identities", "users", on_delete: :cascade
  add_foreign_key "localized_script_version_attributes", "script_versions", on_delete: :cascade
  add_foreign_key "mentions", "users"
  add_foreign_key "messages", "conversations", on_delete: :cascade
  add_foreign_key "reports", "users", column: "reporter_id", on_delete: :cascade
  add_foreign_key "roles_users", "users", on_delete: :cascade
  add_foreign_key "screenshots_script_versions", "script_versions", on_delete: :cascade
  add_foreign_key "script_applies_tos", "scripts", name: "fk_script_applies_tos_script_id"
  add_foreign_key "script_invitations", "scripts", on_delete: :cascade
  add_foreign_key "script_invitations", "users", column: "invited_user_id", on_delete: :cascade
  add_foreign_key "script_reports", "scripts", column: "reference_script_id", on_delete: :cascade
  add_foreign_key "script_reports", "scripts", on_delete: :cascade
  add_foreign_key "script_reports", "users", column: "reporter_id", on_delete: :nullify
  add_foreign_key "script_sets", "users", on_delete: :cascade
  add_foreign_key "script_similarities", "scripts", column: "other_script_id", on_delete: :cascade
  add_foreign_key "script_similarities", "scripts", on_delete: :cascade
  add_foreign_key "script_versions", "scripts", name: "fk_script_versions_script_id"
  add_foreign_key "scripts", "scripts", column: "promoted_script_id", on_delete: :nullify
end
