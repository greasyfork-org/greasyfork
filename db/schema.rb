# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140301023544) do

  create_table "GDN_Activity", primary_key: "ActivityID", force: true do |t|
    t.integer  "CommentActivityID"
    t.integer  "ActivityTypeID",                           null: false
    t.integer  "ActivityUserID"
    t.integer  "RegardingUserID"
    t.text     "Story"
    t.string   "Route"
    t.integer  "CountComments",                default: 0, null: false
    t.integer  "InsertUserID"
    t.datetime "DateInserted",                             null: false
    t.string   "InsertIPAddress",   limit: 15
    t.integer  "Emailed",           limit: 1,  default: 0, null: false
  end

  add_index "GDN_Activity", ["ActivityUserID"], name: "FK_Activity_ActivityUserID", using: :btree
  add_index "GDN_Activity", ["CommentActivityID"], name: "FK_Activity_CommentActivityID", using: :btree
  add_index "GDN_Activity", ["InsertUserID"], name: "FK_Activity_InsertUserID", using: :btree
  add_index "GDN_Activity", ["RegardingUserID"], name: "FK_Activity_RegardingUserID", using: :btree

  create_table "GDN_ActivityType", primary_key: "ActivityTypeID", force: true do |t|
    t.string  "Name",            limit: 20,             null: false
    t.integer "AllowComments",   limit: 1,  default: 0, null: false
    t.integer "ShowIcon",        limit: 1,  default: 0, null: false
    t.string  "ProfileHeadline",                        null: false
    t.string  "FullHeadline",                           null: false
    t.string  "RouteCode"
    t.integer "Notify",          limit: 1,  default: 0, null: false
    t.integer "Public",          limit: 1,  default: 1, null: false
  end

  create_table "GDN_AnalyticsLocal", id: false, force: true do |t|
    t.string  "TimeSlot", limit: 8, null: false
    t.integer "Views"
  end

  add_index "GDN_AnalyticsLocal", ["TimeSlot"], name: "UX_AnalyticsLocal", unique: true, using: :btree

  create_table "GDN_Ban", primary_key: "BanID", force: true do |t|
    t.string   "BanType",                   limit: 9,              null: false
    t.string   "BanValue",                  limit: 50,             null: false
    t.string   "Notes"
    t.integer  "CountUsers",                           default: 0, null: false
    t.integer  "CountBlockedRegistrations",            default: 0, null: false
    t.integer  "InsertUserID",                                     null: false
    t.datetime "DateInserted",                                     null: false
  end

  add_index "GDN_Ban", ["BanType", "BanValue"], name: "UX_Ban", unique: true, using: :btree

  create_table "GDN_Category", primary_key: "CategoryID", force: true do |t|
    t.integer  "ParentCategoryID"
    t.integer  "TreeLeft"
    t.integer  "TreeRight"
    t.integer  "Depth"
    t.integer  "CountDiscussions",                 default: 0,  null: false
    t.integer  "CountComments",                    default: 0,  null: false
    t.datetime "DateMarkedRead"
    t.integer  "AllowDiscussions",     limit: 1,   default: 1,  null: false
    t.integer  "Archived",             limit: 1,   default: 0,  null: false
    t.string   "Name",                                          null: false
    t.string   "UrlCode"
    t.string   "Description",          limit: 500
    t.integer  "Sort"
    t.integer  "PermissionCategoryID",             default: -1, null: false
    t.integer  "InsertUserID",                                  null: false
    t.integer  "UpdateUserID"
    t.datetime "DateInserted",                                  null: false
    t.datetime "DateUpdated",                                   null: false
    t.integer  "LastCommentID"
    t.integer  "LastDiscussionID"
  end

  add_index "GDN_Category", ["InsertUserID"], name: "FK_Category_InsertUserID", using: :btree

  create_table "GDN_Comment", primary_key: "CommentID", force: true do |t|
    t.integer  "DiscussionID",                           null: false
    t.integer  "InsertUserID"
    t.integer  "UpdateUserID"
    t.integer  "DeleteUserID"
    t.text     "Body",                                   null: false
    t.string   "Format",          limit: 20
    t.datetime "DateInserted"
    t.datetime "DateDeleted"
    t.datetime "DateUpdated"
    t.string   "InsertIPAddress", limit: 15
    t.string   "UpdateIPAddress", limit: 15
    t.integer  "Flag",            limit: 1,  default: 0, null: false
    t.float    "Score"
    t.text     "Attributes"
  end

  add_index "GDN_Comment", ["Body"], name: "TX_Comment", type: :fulltext
  add_index "GDN_Comment", ["DateInserted"], name: "FK_Comment_DateInserted", using: :btree
  add_index "GDN_Comment", ["DiscussionID"], name: "FK_Comment_DiscussionID", using: :btree
  add_index "GDN_Comment", ["InsertUserID"], name: "FK_Comment_InsertUserID", using: :btree

  create_table "GDN_Conversation", primary_key: "ConversationID", force: true do |t|
    t.string   "Subject",         limit: 100
    t.string   "Contributors",                            null: false
    t.integer  "FirstMessageID"
    t.integer  "InsertUserID",                            null: false
    t.datetime "DateInserted"
    t.string   "InsertIPAddress", limit: 15
    t.integer  "UpdateUserID",                            null: false
    t.datetime "DateUpdated",                             null: false
    t.string   "UpdateIPAddress", limit: 15
    t.integer  "CountMessages",               default: 0, null: false
    t.integer  "LastMessageID"
    t.integer  "RegardingID"
  end

  add_index "GDN_Conversation", ["DateInserted"], name: "FK_Conversation_DateInserted", using: :btree
  add_index "GDN_Conversation", ["FirstMessageID"], name: "FK_Conversation_FirstMessageID", using: :btree
  add_index "GDN_Conversation", ["InsertUserID"], name: "FK_Conversation_InsertUserID", using: :btree
  add_index "GDN_Conversation", ["RegardingID"], name: "IX_Conversation_RegardingID", using: :btree
  add_index "GDN_Conversation", ["UpdateUserID"], name: "FK_Conversation_UpdateUserID", using: :btree

  create_table "GDN_ConversationMessage", primary_key: "MessageID", force: true do |t|
    t.integer  "ConversationID",             null: false
    t.text     "Body",                       null: false
    t.string   "Format",          limit: 20
    t.integer  "InsertUserID"
    t.datetime "DateInserted",               null: false
    t.string   "InsertIPAddress", limit: 15
  end

  add_index "GDN_ConversationMessage", ["ConversationID"], name: "FK_ConversationMessage_ConversationID", using: :btree

  create_table "GDN_Discussion", primary_key: "DiscussionID", force: true do |t|
    t.string   "Type",              limit: 10
    t.string   "ForeignID",         limit: 30
    t.integer  "CategoryID",                                null: false
    t.integer  "InsertUserID",                              null: false
    t.integer  "UpdateUserID",                              null: false
    t.integer  "LastCommentID"
    t.string   "Name",              limit: 100,             null: false
    t.text     "Body",                                      null: false
    t.string   "Format",            limit: 20
    t.string   "Tags"
    t.integer  "CountComments",                 default: 1, null: false
    t.integer  "CountBookmarks"
    t.integer  "CountViews",                    default: 1, null: false
    t.integer  "Closed",            limit: 1,   default: 0, null: false
    t.integer  "Announce",          limit: 1,   default: 0, null: false
    t.integer  "Sink",              limit: 1,   default: 0, null: false
    t.datetime "DateInserted"
    t.datetime "DateUpdated",                               null: false
    t.string   "InsertIPAddress",   limit: 15
    t.string   "UpdateIPAddress",   limit: 15
    t.datetime "DateLastComment"
    t.integer  "LastCommentUserID"
    t.float    "Score"
    t.text     "Attributes"
    t.integer  "RegardingID"
    t.integer  "ScriptID"
  end

  add_index "GDN_Discussion", ["CategoryID"], name: "FK_Discussion_CategoryID", using: :btree
  add_index "GDN_Discussion", ["DateLastComment"], name: "IX_Discussion_DateLastComment", using: :btree
  add_index "GDN_Discussion", ["ForeignID"], name: "IX_Discussion_ForeignID", using: :btree
  add_index "GDN_Discussion", ["InsertUserID"], name: "FK_Discussion_InsertUserID", using: :btree
  add_index "GDN_Discussion", ["Name", "Body"], name: "TX_Discussion", type: :fulltext
  add_index "GDN_Discussion", ["RegardingID"], name: "IX_Discussion_RegardingID", using: :btree
  add_index "GDN_Discussion", ["Type"], name: "IX_Discussion_Type", using: :btree

  create_table "GDN_Draft", primary_key: "DraftID", force: true do |t|
    t.integer  "DiscussionID"
    t.integer  "CategoryID"
    t.integer  "InsertUserID",                         null: false
    t.integer  "UpdateUserID",                         null: false
    t.string   "Name",         limit: 100
    t.string   "Tags"
    t.integer  "Closed",       limit: 1,   default: 0, null: false
    t.integer  "Announce",     limit: 1,   default: 0, null: false
    t.integer  "Sink",         limit: 1,   default: 0, null: false
    t.text     "Body",                                 null: false
    t.string   "Format",       limit: 20
    t.datetime "DateInserted",                         null: false
    t.datetime "DateUpdated"
  end

  add_index "GDN_Draft", ["CategoryID"], name: "FK_Draft_CategoryID", using: :btree
  add_index "GDN_Draft", ["DiscussionID"], name: "FK_Draft_DiscussionID", using: :btree
  add_index "GDN_Draft", ["InsertUserID"], name: "FK_Draft_InsertUserID", using: :btree

  create_table "GDN_Invitation", primary_key: "InvitationID", force: true do |t|
    t.string   "Email",          limit: 200, null: false
    t.string   "Code",           limit: 50,  null: false
    t.integer  "InsertUserID"
    t.datetime "DateInserted",               null: false
    t.integer  "AcceptedUserID"
  end

  add_index "GDN_Invitation", ["InsertUserID"], name: "FK_Invitation_InsertUserID", using: :btree

  create_table "GDN_Log", primary_key: "LogID", force: true do |t|
    t.string   "Operation",       limit: 8,  null: false
    t.string   "RecordType",      limit: 12, null: false
    t.integer  "RecordID"
    t.integer  "RecordUserID"
    t.datetime "RecordDate",                 null: false
    t.string   "RecordIPAddress", limit: 15
    t.integer  "InsertUserID",               null: false
    t.datetime "DateInserted",               null: false
    t.string   "InsertIPAddress", limit: 15
    t.string   "OtherUserIDs"
    t.datetime "DateUpdated"
    t.integer  "ParentRecordID"
    t.text     "Data"
    t.integer  "CountGroup"
  end

  add_index "GDN_Log", ["ParentRecordID"], name: "IX_Log_ParentRecordID", using: :btree
  add_index "GDN_Log", ["RecordID"], name: "IX_Log_RecordID", using: :btree
  add_index "GDN_Log", ["RecordIPAddress"], name: "IX_Log_RecordIPAddress", using: :btree
  add_index "GDN_Log", ["RecordType"], name: "IX_Log_RecordType", using: :btree

  create_table "GDN_Message", primary_key: "MessageID", force: true do |t|
    t.text    "Content",                             null: false
    t.string  "Format",       limit: 20
    t.integer "AllowDismiss", limit: 1,  default: 1, null: false
    t.integer "Enabled",      limit: 1,  default: 1, null: false
    t.string  "Application"
    t.string  "Controller"
    t.string  "Method"
    t.string  "AssetTarget",  limit: 20
    t.string  "CssClass",     limit: 20
    t.integer "Sort"
  end

  create_table "GDN_Permission", primary_key: "PermissionID", force: true do |t|
    t.integer "RoleID",                                         default: 0, null: false
    t.string  "JunctionTable",                      limit: 100
    t.string  "JunctionColumn",                     limit: 100
    t.integer "JunctionID"
    t.integer "Garden.Email.Manage",                limit: 1,   default: 0, null: false
    t.integer "Garden.Settings.Manage",             limit: 1,   default: 0, null: false
    t.integer "Garden.Settings.View",               limit: 1,   default: 0, null: false
    t.integer "Garden.Routes.Manage",               limit: 1,   default: 0, null: false
    t.integer "Garden.Messages.Manage",             limit: 1,   default: 0, null: false
    t.integer "Garden.Applications.Manage",         limit: 1,   default: 0, null: false
    t.integer "Garden.Plugins.Manage",              limit: 1,   default: 0, null: false
    t.integer "Garden.Themes.Manage",               limit: 1,   default: 0, null: false
    t.integer "Garden.SignIn.Allow",                limit: 1,   default: 0, null: false
    t.integer "Garden.Registration.Manage",         limit: 1,   default: 0, null: false
    t.integer "Garden.Applicants.Manage",           limit: 1,   default: 0, null: false
    t.integer "Garden.Roles.Manage",                limit: 1,   default: 0, null: false
    t.integer "Garden.Users.Add",                   limit: 1,   default: 0, null: false
    t.integer "Garden.Users.Edit",                  limit: 1,   default: 0, null: false
    t.integer "Garden.Users.Delete",                limit: 1,   default: 0, null: false
    t.integer "Garden.Users.Approve",               limit: 1,   default: 0, null: false
    t.integer "Garden.Activity.Delete",             limit: 1,   default: 0, null: false
    t.integer "Garden.Activity.View",               limit: 1,   default: 0, null: false
    t.integer "Garden.Profiles.View",               limit: 1,   default: 0, null: false
    t.integer "Garden.Profiles.Edit",               limit: 1,   default: 0, null: false
    t.integer "Garden.Moderation.Manage",           limit: 1,   default: 0, null: false
    t.integer "Garden.AdvancedNotifications.Allow", limit: 1,   default: 0, null: false
    t.integer "Conversations.Moderation.Manage",    limit: 1,   default: 0, null: false
    t.integer "Vanilla.Settings.Manage",            limit: 1,   default: 0, null: false
    t.integer "Vanilla.Categories.Manage",          limit: 1,   default: 0, null: false
    t.integer "Vanilla.Spam.Manage",                limit: 1,   default: 0, null: false
    t.integer "Vanilla.Discussions.View",           limit: 1,   default: 0, null: false
    t.integer "Vanilla.Discussions.Add",            limit: 1,   default: 0, null: false
    t.integer "Vanilla.Discussions.Edit",           limit: 1,   default: 0, null: false
    t.integer "Vanilla.Discussions.Announce",       limit: 1,   default: 0, null: false
    t.integer "Vanilla.Discussions.Sink",           limit: 1,   default: 0, null: false
    t.integer "Vanilla.Discussions.Close",          limit: 1,   default: 0, null: false
    t.integer "Vanilla.Discussions.Delete",         limit: 1,   default: 0, null: false
    t.integer "Vanilla.Comments.Add",               limit: 1,   default: 0, null: false
    t.integer "Vanilla.Comments.Edit",              limit: 1,   default: 0, null: false
    t.integer "Vanilla.Comments.Delete",            limit: 1,   default: 0, null: false
  end

  add_index "GDN_Permission", ["RoleID"], name: "FK_Permission_RoleID", using: :btree

  create_table "GDN_Photo", primary_key: "PhotoID", force: true do |t|
    t.string   "Name",         null: false
    t.integer  "InsertUserID"
    t.datetime "DateInserted", null: false
  end

  add_index "GDN_Photo", ["InsertUserID"], name: "FK_Photo_InsertUserID", using: :btree

  create_table "GDN_Regarding", primary_key: "RegardingID", force: true do |t|
    t.string   "Type",                       null: false
    t.integer  "InsertUserID",               null: false
    t.datetime "DateInserted",               null: false
    t.string   "ForeignType",     limit: 32, null: false
    t.integer  "ForeignID",                  null: false
    t.text     "OriginalContent"
    t.string   "ParentType",      limit: 32
    t.integer  "ParentID"
    t.string   "ForeignURL"
    t.text     "Comment",                    null: false
    t.integer  "Reports"
  end

  add_index "GDN_Regarding", ["Type"], name: "FK_Regarding_Type", using: :btree

  create_table "GDN_Role", primary_key: "RoleID", force: true do |t|
    t.string  "Name",        limit: 100,             null: false
    t.string  "Description", limit: 500
    t.integer "Sort"
    t.integer "Deletable",   limit: 1,   default: 1, null: false
    t.integer "CanSession",  limit: 1,   default: 1, null: false
  end

  create_table "GDN_Session", primary_key: "SessionID", force: true do |t|
    t.integer  "UserID",                  default: 0, null: false
    t.datetime "DateInserted",                        null: false
    t.datetime "DateUpdated",                         null: false
    t.string   "TransientKey", limit: 12,             null: false
    t.text     "Attributes"
  end

  create_table "GDN_Spammer", primary_key: "UserID", force: true do |t|
    t.integer "CountSpam",        limit: 2, default: 0, null: false
    t.integer "CountDeletedSpam", limit: 2, default: 0, null: false
  end

  create_table "GDN_Tag", primary_key: "TagID", force: true do |t|
    t.string   "Name",                                    null: false
    t.string   "Type",             limit: 10
    t.integer  "InsertUserID"
    t.datetime "DateInserted",                            null: false
    t.integer  "CountDiscussions",            default: 0, null: false
  end

  add_index "GDN_Tag", ["InsertUserID"], name: "FK_Tag_InsertUserID", using: :btree
  add_index "GDN_Tag", ["Name"], name: "UX_Tag", unique: true, using: :btree
  add_index "GDN_Tag", ["Type"], name: "IX_Tag_Type", using: :btree

  create_table "GDN_TagDiscussion", id: false, force: true do |t|
    t.integer "TagID",        null: false
    t.integer "DiscussionID", null: false
  end

  create_table "GDN_User", primary_key: "UserID", force: true do |t|
    t.string   "Name",                     limit: 50,                null: false
    t.binary   "Password",                 limit: 100,               null: false
    t.string   "HashMethod",               limit: 10
    t.string   "Photo"
    t.text     "About"
    t.string   "Email",                    limit: 200,               null: false
    t.integer  "ShowEmail",                limit: 1,   default: 0,   null: false
    t.string   "Gender",                   limit: 1,   default: "m", null: false
    t.integer  "CountVisits",                          default: 0,   null: false
    t.integer  "CountInvitations",                     default: 0,   null: false
    t.integer  "CountNotifications"
    t.integer  "InviteUserID"
    t.text     "DiscoveryText"
    t.text     "Preferences"
    t.text     "Permissions"
    t.text     "Attributes"
    t.datetime "DateSetInvitations"
    t.datetime "DateOfBirth"
    t.datetime "DateFirstVisit"
    t.datetime "DateLastActive"
    t.string   "LastIPAddress",            limit: 15
    t.datetime "DateInserted",                                       null: false
    t.string   "InsertIPAddress",          limit: 15
    t.datetime "DateUpdated"
    t.string   "UpdateIPAddress",          limit: 15
    t.integer  "HourOffset",                           default: 0,   null: false
    t.float    "Score"
    t.integer  "Admin",                    limit: 1,   default: 0,   null: false
    t.integer  "Banned",                   limit: 1,   default: 0,   null: false
    t.integer  "Deleted",                  limit: 1,   default: 0,   null: false
    t.integer  "CountUnreadConversations"
    t.integer  "CountDiscussions"
    t.integer  "CountUnreadDiscussions"
    t.integer  "CountComments"
    t.integer  "CountDrafts"
    t.integer  "CountBookmarks"
  end

  add_index "GDN_User", ["Email"], name: "IX_User_Email", using: :btree
  add_index "GDN_User", ["Name"], name: "FK_User_Name", using: :btree

  create_table "GDN_UserAuthentication", id: false, force: true do |t|
    t.string  "ForeignUserKey",            null: false
    t.string  "ProviderKey",    limit: 64, null: false
    t.integer "UserID",                    null: false
  end

  add_index "GDN_UserAuthentication", ["UserID"], name: "FK_UserAuthentication_UserID", using: :btree

  create_table "GDN_UserAuthenticationNonce", primary_key: "Nonce", force: true do |t|
    t.string    "Token",     limit: 128, null: false
    t.timestamp "Timestamp",             null: false
  end

  create_table "GDN_UserAuthenticationProvider", primary_key: "AuthenticationKey", force: true do |t|
    t.string "AuthenticationSchemeAlias", limit: 32, null: false
    t.string "Name",                      limit: 50
    t.string "URL"
    t.text   "AssociationSecret",                    null: false
    t.string "AssociationHashMethod",     limit: 20, null: false
    t.string "AuthenticateUrl"
    t.string "RegisterUrl"
    t.string "SignInUrl"
    t.string "SignOutUrl"
    t.string "PasswordUrl"
    t.string "ProfileUrl"
    t.text   "Attributes"
  end

  create_table "GDN_UserAuthenticationToken", id: false, force: true do |t|
    t.string    "Token",          limit: 128, null: false
    t.string    "ProviderKey",    limit: 64,  null: false
    t.string    "ForeignUserKey"
    t.string    "TokenSecret",    limit: 64,  null: false
    t.string    "TokenType",      limit: 7,   null: false
    t.integer   "Authorized",     limit: 1,   null: false
    t.timestamp "Timestamp",                  null: false
    t.integer   "Lifetime",                   null: false
  end

  create_table "GDN_UserCategory", id: false, force: true do |t|
    t.integer  "UserID",                               null: false
    t.integer  "CategoryID",                           null: false
    t.datetime "DateMarkedRead"
    t.integer  "Unfollow",       limit: 1, default: 0, null: false
  end

  create_table "GDN_UserComment", id: false, force: true do |t|
    t.integer  "UserID",         null: false
    t.integer  "CommentID",      null: false
    t.float    "Score"
    t.datetime "DateLastViewed"
  end

  create_table "GDN_UserConversation", id: false, force: true do |t|
    t.integer  "UserID",                                  null: false
    t.integer  "ConversationID",                          null: false
    t.integer  "CountReadMessages",           default: 0, null: false
    t.integer  "LastMessageID"
    t.datetime "DateLastViewed"
    t.datetime "DateCleared"
    t.integer  "Bookmarked",        limit: 1, default: 0, null: false
    t.integer  "Deleted",           limit: 1, default: 0, null: false
  end

  add_index "GDN_UserConversation", ["LastMessageID"], name: "FK_UserConversation_LastMessageID", using: :btree

  create_table "GDN_UserDiscussion", id: false, force: true do |t|
    t.integer  "UserID",                               null: false
    t.integer  "DiscussionID",                         null: false
    t.float    "Score"
    t.integer  "CountComments",            default: 0, null: false
    t.datetime "DateLastViewed"
    t.integer  "Dismissed",      limit: 1, default: 0, null: false
    t.integer  "Bookmarked",     limit: 1, default: 0, null: false
  end

  add_index "GDN_UserDiscussion", ["DiscussionID"], name: "FK_UserDiscussion_DiscussionID", using: :btree

  create_table "GDN_UserMeta", id: false, force: true do |t|
    t.integer "UserID", null: false
    t.string  "Name",   null: false
    t.text    "Value"
  end

  add_index "GDN_UserMeta", ["Name"], name: "IX_UserMeta_Name", using: :btree

  create_table "GDN_UserRole", id: false, force: true do |t|
    t.integer "UserID", null: false
    t.integer "RoleID", null: false
  end

  create_table "allowed_requires", force: true do |t|
    t.string   "pattern",                null: false
    t.string   "name",                   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url",        limit: 500
  end

  create_table "assessment_reasons", force: true do |t|
    t.string   "name",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "assessments", force: true do |t|
    t.integer  "scripts_id",            null: false
    t.integer  "assessment_reasons_id", null: false
    t.string   "details"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "daily_install_counts", force: true do |t|
    t.integer   "script_id",               null: false
    t.string    "ip",           limit: 15, null: false
    t.timestamp "install_date",            null: false
  end

  add_index "daily_install_counts", ["script_id", "ip"], name: "index_daily_install_counts_on_script_id_and_ip", unique: true, using: :btree

  create_table "disallowed_codes", force: true do |t|
    t.string   "pattern",     null: false
    t.string   "description", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "install_counts", force: true do |t|
    t.integer "script_id",    null: false
    t.date    "install_date", null: false
    t.integer "installs",     null: false
  end

  add_index "install_counts", ["script_id", "install_date"], name: "index_install_counts_on_script_id_and_install_date", unique: true, using: :btree

  create_table "script_applies_tos", force: true do |t|
    t.integer  "script_id",    null: false
    t.text     "display_text", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "script_applies_tos", ["script_id"], name: "index_script_applies_tos_on_script_id", using: :btree

  create_table "script_versions", force: true do |t|
    t.integer  "script_id",                                                null: false
    t.text     "changelog"
    t.text     "additional_info"
    t.text     "version",                                                  null: false
    t.text     "code",                   limit: 16777215,                  null: false
    t.text     "rewritten_code",         limit: 16777215,                  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "additional_info_markup", limit: 10,       default: "html", null: false
  end

  add_index "script_versions", ["script_id"], name: "index_script_versions_on_script_id", using: :btree

  create_table "scripts", force: true do |t|
    t.string   "name",                   limit: 100,                  null: false
    t.text     "description",                                         null: false
    t.text     "additional_info"
    t.integer  "user_id",                                             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "userscripts_id"
    t.integer  "daily_installs",                     default: 0,      null: false
    t.integer  "total_installs",                     default: 0,      null: false
    t.string   "additional_info_markup", limit: 10,  default: "html", null: false
  end

  add_index "scripts", ["user_id"], name: "index_scripts_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                                default: "",     null: false
    t.string   "encrypted_password",                   default: "",     null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                        default: 0,      null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                   limit: 50,                     null: false
    t.string   "profile",                limit: 10000
    t.string   "profile_markup",         limit: 10,    default: "html", null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
