# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2024_09_23_202914) do
  create_table "GDN_Comment", primary_key: "CommentID", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
    t.integer "DiscussionID", null: false
    t.integer "InsertUserID"
    t.integer "UpdateUserID"
    t.integer "DeleteUserID"
    t.text "Body", null: false
    t.string "Format", limit: 20
    t.datetime "DateInserted", precision: nil
    t.datetime "DateDeleted", precision: nil
    t.datetime "DateUpdated", precision: nil
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

  create_table "GDN_Discussion", primary_key: "DiscussionID", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=MyISAM", force: :cascade do |t|
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
    t.datetime "DateInserted", precision: nil, null: false
    t.datetime "DateUpdated", precision: nil
    t.binary "InsertIPAddress", limit: 16
    t.binary "UpdateIPAddress", limit: 16
    t.datetime "DateLastComment", precision: nil
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

  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "akismet_submissions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.text "akismet_params", size: :medium, null: false
    t.boolean "result_spam", null: false
    t.boolean "result_blatant", null: false
    t.index ["item_type", "item_id"], name: "index_akismet_submissions_on_item_type_and_item_id"
  end

  create_table "allowed_requires", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "pattern", null: false
    t.string "name", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "url", limit: 500
    t.text "comment"
  end

  create_table "antifeatures", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.integer "locale_id"
    t.integer "antifeature_type", null: false
    t.text "description"
    t.index ["locale_id"], name: "index_antifeatures_on_locale_id"
    t.index ["script_id"], name: "index_antifeatures_on_script_id"
  end

  create_table "author_email_notification_types", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", limit: 20, null: false
    t.string "description", limit: 100, null: false
  end

  create_table "authors", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.bigint "user_id", null: false
    t.index ["script_id", "user_id"], name: "index_authors_on_script_id_and_user_id", unique: true
    t.index ["user_id"], name: "fk_rails_46e884287b"
  end

  create_table "banned_email_hashes", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "email_hash", null: false
    t.datetime "deleted_at", precision: nil, null: false
    t.datetime "banned_at", precision: nil
    t.index ["email_hash"], name: "index_banned_email_hashes_on_email_hash", unique: true
  end

  create_table "blocked_script_codes", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "pattern", null: false
    t.string "public_reason", null: false
    t.string "private_reason", null: false
    t.boolean "serious", default: false, null: false
    t.integer "originating_script_id"
    t.boolean "case_insensitive", default: false, null: false
    t.boolean "notify_admin", default: true, null: false
    t.index ["originating_script_id"], name: "fk_rails_6f37f4eb64"
  end

  create_table "blocked_script_texts", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "text", null: false
    t.string "public_reason", null: false
    t.string "private_reason", null: false
    t.string "result", limit: 10, null: false
  end

  create_table "blocked_script_urls", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "url", null: false
    t.string "public_reason", null: false
    t.string "private_reason", null: false
    t.boolean "prefix", default: false, null: false
  end

  create_table "browsers", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "code", limit: 20, null: false
    t.string "name", limit: 20, null: false
  end

  create_table "cleaned_codes", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.text "code", size: :long, null: false
    t.index ["script_id"], name: "index_cleaned_codes_on_script_id", unique: true
  end

  create_table "comments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "discussion_id", null: false
    t.integer "poster_id", null: false
    t.text "text", null: false
    t.string "text_markup", limit: 10, default: "html", null: false
    t.datetime "edited_at", precision: nil
    t.boolean "first_comment", default: false, null: false
    t.datetime "deleted_at", precision: nil
    t.integer "deleted_by_user_id"
    t.string "review_reason", limit: 10
    t.text "plain_text"
    t.index ["discussion_id"], name: "index_comments_on_discussion_id"
    t.index ["poster_id"], name: "index_comments_on_poster_id"
  end

  create_table "compatibilities", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.integer "browser_id", null: false
    t.boolean "compatible", null: false
    t.string "comments", limit: 200
    t.index ["browser_id"], name: "fk_rails_d7eb310317"
    t.index ["script_id"], name: "index_compatibilities_on_script_id"
  end

  create_table "conversation_subscriptions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "user_id"], name: "index_conversation_subscriptions_on_conversation_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_conversation_subscriptions_on_user_id"
  end

  create_table "conversations", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "stat_last_message_date", precision: nil
    t.integer "stat_last_poster_id"
  end

  create_table "conversations_users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.integer "user_id", null: false
    t.index ["conversation_id"], name: "fk_rails_fa156dfe4c"
  end

  create_table "daily_install_counts", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.string "ip", limit: 45, null: false
    t.timestamp "install_date", default: -> { "current_timestamp()" }, null: false
    t.index ["script_id", "ip"], name: "index_daily_install_counts_on_script_id_and_ip", unique: true
  end

  create_table "daily_update_check_counts", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.datetime "update_date", precision: nil, null: false
    t.string "ip", limit: 45, null: false
    t.index ["script_id", "ip"], name: "update_script_id_and_ip", unique: true
  end

  create_table "disallowed_attributes", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "attribute_name", limit: 50, null: false
    t.string "pattern", null: false
    t.string "reason", null: false
    t.string "object_type", null: false
  end

  create_table "disallowed_codes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "pattern", null: false
    t.string "description", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "originating_script_id"
    t.boolean "slow_ban", default: false, null: false
  end

  create_table "discussion_categories", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "category_key", limit: 20, null: false
    t.boolean "moderators_only", default: false, null: false
  end

  create_table "discussion_reads", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "discussion_id", null: false
    t.bigint "user_id", null: false
    t.datetime "read_at", precision: nil, null: false
    t.index ["discussion_id"], name: "index_discussion_reads_on_discussion_id"
    t.index ["user_id", "discussion_id"], name: "index_discussion_reads_on_user_id_and_discussion_id", unique: true
  end

  create_table "discussion_subscriptions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "discussion_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discussion_id", "user_id"], name: "index_discussion_subscriptions_on_discussion_id_and_user_id", unique: true
    t.index ["user_id"], name: "index_discussion_subscriptions_on_user_id"
  end

  create_table "discussions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "poster_id", null: false
    t.integer "script_id"
    t.integer "rating"
    t.integer "stat_reply_count", default: 0, null: false
    t.datetime "stat_last_reply_date", precision: nil
    t.integer "stat_last_replier_id"
    t.integer "migrated_from"
    t.integer "discussion_category_id", null: false
    t.string "title"
    t.datetime "deleted_at", precision: nil
    t.integer "deleted_by_user_id"
    t.string "review_reason", limit: 10
    t.integer "stat_first_comment_id"
    t.integer "locale_id"
    t.integer "report_id"
    t.boolean "publicly_visible", default: true, null: false
    t.index ["locale_id"], name: "index_discussions_on_locale_id"
    t.index ["migrated_from"], name: "index_discussions_on_migrated_from"
    t.index ["poster_id"], name: "index_discussions_on_poster_id"
    t.index ["publicly_visible"], name: "index_discussions_on_publicly_visible"
    t.index ["report_id"], name: "index_discussions_on_report_id"
    t.index ["script_id"], name: "fk_rails_a52537835c"
    t.index ["stat_last_reply_date"], name: "index_discussions_on_stat_last_reply_date"
  end

  create_table "identities", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", limit: 20, null: false
    t.string "uid", limit: 100, null: false
    t.string "url", limit: 500
    t.boolean "syncing", null: false
    t.index ["uid", "provider"], name: "index_identities_on_uid_and_provider", unique: true
    t.index ["user_id"], name: "fk_rails_5373344100"
  end

  create_table "install_counts", charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.date "install_date", null: false
    t.integer "installs", null: false
    t.index ["script_id", "install_date"], name: "index_install_counts_on_script_id_and_install_date", unique: true
  end

  create_table "licenses", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "code", limit: 100, null: false
    t.string "name", limit: 250, null: false
    t.string "url", limit: 250
    t.string "summary_url"
  end

  create_table "locale_contributors", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "locale_id", null: false
    t.string "transifex_user_name", limit: 50, null: false
    t.index ["locale_id"], name: "index_locale_contributors_on_locale_id"
  end

  create_table "locales", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "code", limit: 20, null: false
    t.boolean "rtl", default: false, null: false
    t.string "detect_language_code", limit: 20
    t.string "english_name", limit: 100, null: false
    t.string "native_name", limit: 100
    t.boolean "ui_available", default: false, null: false
    t.integer "percent_complete", default: 0
  end

  create_table "localized_script_attributes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.integer "locale_id", null: false
    t.string "attribute_key", null: false
    t.string "value_markup", null: false
    t.text "attribute_value", null: false
    t.boolean "attribute_default", null: false
    t.string "sync_identifier"
    t.index ["locale_id"], name: "index_localized_script_attributes_on_locale_id"
    t.index ["script_id"], name: "index_localized_script_attributes_on_script_id"
  end

  create_table "localized_script_version_attributes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_version_id", null: false
    t.integer "locale_id", null: false
    t.string "attribute_key", null: false
    t.string "value_markup", null: false
    t.text "attribute_value", null: false
    t.boolean "attribute_default", null: false
    t.index ["locale_id"], name: "index_localized_script_version_attributes_on_locale_id"
    t.index ["script_version_id"], name: "index_localized_script_version_attributes_on_script_version_id"
  end

  create_table "mentions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "mentioning_item_type", null: false
    t.bigint "mentioning_item_id", null: false
    t.bigint "user_id", null: false
    t.string "text", null: false
    t.index ["mentioning_item_type", "mentioning_item_id", "user_id"], name: "mention_mentioning"
    t.index ["user_id"], name: "fk_rails_1b711e94aa"
  end

  create_table "messages", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "conversation_id", null: false
    t.integer "poster_id", null: false
    t.string "content", limit: 10000, null: false
    t.string "content_markup", limit: 10, default: "html", null: false
    t.datetime "edited_at", precision: nil
    t.index ["conversation_id"], name: "fk_rails_7f927086d2"
    t.index ["poster_id"], name: "index_messages_on_poster_id"
  end

  create_table "moderator_actions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "script_id"
    t.integer "moderator_id", null: false
    t.text "action", null: false
    t.string "reason"
    t.integer "user_id"
    t.text "private_reason"
    t.bigint "report_id"
    t.bigint "script_report_id"
    t.integer "script_lock_appeal_id"
    t.index ["report_id"], name: "fk_rails_982b48b755"
    t.index ["script_report_id"], name: "fk_rails_de8c1b0dd2"
    t.index ["user_id"], name: "index_moderator_actions_on_user_id"
  end

  create_table "notifications", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.integer "notification_type", null: false
    t.datetime "created_at", null: false
    t.datetime "read_at"
    t.index ["item_type", "item_id"], name: "index_notifications_on_item"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "item_type", "item_id"], name: "index_notifications_on_user_id_and_item_type_and_item_id"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
  end

  create_table "redirect_service_domains", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "domain", limit: 50, null: false
  end

  create_table "reports", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "reason", limit: 25, null: false
    t.text "explanation"
    t.bigint "reporter_id"
    t.string "result", limit: 20
    t.string "auto_reporter", limit: 10
    t.string "explanation_markup", limit: 10, default: "html", null: false
    t.string "script_url"
    t.integer "reference_script_id"
    t.text "rebuttal"
    t.integer "rebuttal_by_user_id"
    t.text "moderator_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "discussion_category_id"
    t.integer "resolver_id"
    t.boolean "self_upheld", default: false
    t.string "moderator_reason_override", limit: 25
    t.index ["item_type", "item_id"], name: "index_reports_on_item_type_and_item_id"
    t.index ["reporter_id"], name: "index_reports_on_reporter_id"
    t.index ["result"], name: "index_reports_on_result"
  end

  create_table "roles", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
  end

  create_table "roles_users", id: false, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "role_id", null: false
    t.index ["role_id"], name: "index_roles_users_on_role_id"
    t.index ["user_id"], name: "index_roles_users_on_user_id"
  end

  create_table "screenshots", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "screenshot_file_name"
    t.string "screenshot_content_type"
    t.integer "screenshot_file_size"
    t.datetime "screenshot_updated_at", precision: nil
    t.string "caption", limit: 500
  end

  create_table "screenshots_script_versions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "screenshot_id"
    t.integer "script_version_id"
    t.index ["screenshot_id"], name: "index_screenshots_script_versions_on_screenshot_id"
    t.index ["script_version_id"], name: "index_screenshots_script_versions_on_script_version_id"
  end

  create_table "script_applies_tos", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.integer "site_application_id", null: false
    t.boolean "tld_extra", default: false, null: false
    t.index ["script_id"], name: "index_script_applies_tos_on_script_id"
  end

  create_table "script_codes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=COMPRESSED", force: :cascade do |t|
    t.text "code", size: :long, null: false
    t.string "code_hash", limit: 40, null: false
    t.index ["code_hash"], name: "index_script_codes_on_code_hash"
  end

  create_table "script_delete_types", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", limit: 10, null: false
    t.string "description", limit: 500, null: false
  end

  create_table "script_invitations", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.bigint "invited_user_id", null: false
    t.datetime "expires_at", precision: nil, null: false
    t.index ["invited_user_id"], name: "fk_rails_55c05503c1"
    t.index ["script_id"], name: "fk_rails_f52d98b0ef"
  end

  create_table "script_lock_appeals", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.bigint "report_id"
    t.text "text", null: false
    t.string "text_markup", limit: 10, default: "html", null: false
    t.integer "resolution", default: 0, null: false
    t.text "moderator_notes"
    t.index ["report_id"], name: "fk_rails_c92d139641"
    t.index ["script_id"], name: "fk_rails_b37644914a"
  end

  create_table "script_set_automatic_set_inclusions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "parent_id", null: false
    t.integer "script_set_automatic_type_id", null: false
    t.string "value", limit: 100
    t.boolean "exclusion", default: false, null: false
    t.index ["parent_id"], name: "index_script_set_automatic_set_inclusions_on_parent_id"
    t.index ["script_set_automatic_type_id"], name: "ssasi_script_set_automatic_type_id"
  end

  create_table "script_set_automatic_types", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", limit: 50, null: false
  end

  create_table "script_set_script_inclusions", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "parent_id", null: false
    t.integer "child_id", null: false
    t.boolean "exclusion", default: false, null: false
    t.index ["child_id"], name: "index_script_set_script_inclusions_on_child_id"
    t.index ["parent_id"], name: "index_script_set_script_inclusions_on_parent_id"
  end

  create_table "script_set_set_inclusions", id: :integer, charset: "utf8mb3", collation: "utf8mb3_unicode_ci", force: :cascade do |t|
    t.integer "parent_id", null: false
    t.integer "child_id", null: false
    t.boolean "exclusion", default: false, null: false
    t.index ["child_id"], name: "index_script_set_set_inclusions_on_child_id"
    t.index ["parent_id"], name: "index_script_set_set_inclusions_on_parent_id"
  end

  create_table "script_sets", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", limit: 100, null: false
    t.text "description", size: :medium, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "favorite", default: false, null: false
    t.string "default_sort", limit: 20
    t.index ["user_id"], name: "index_script_sets_on_user_id"
  end

  create_table "script_similarities", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.integer "other_script_id", null: false
    t.decimal "similarity", precision: 4, scale: 3, null: false
    t.datetime "checked_at", precision: nil, null: false
    t.boolean "tersed", default: false, null: false
    t.index ["other_script_id"], name: "fk_rails_3fba862a5b"
    t.index ["script_id", "other_script_id", "tersed"], name: "script_similarity_search", unique: true
  end

  create_table "script_subresource_usages", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "script_id", null: false
    t.bigint "subresource_id", null: false
    t.string "algorithm", limit: 20
    t.string "integrity_hash", limit: 128
    t.string "encoding", limit: 10
    t.index ["script_id"], name: "index_script_subresource_usages_on_script_id"
    t.index ["subresource_id"], name: "index_script_subresource_usages_on_subresource_id"
  end

  create_table "script_versions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.text "changelog", size: :medium
    t.string "changelog_markup", limit: 10, default: "text", null: false
    t.string "version", limit: 200, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "script_code_id", null: false
    t.integer "rewritten_script_code_id", null: false
    t.boolean "not_js_convertible_override", default: false, null: false
    t.index ["rewritten_script_code_id"], name: "index_script_versions_on_rewritten_script_code_id"
    t.index ["script_code_id"], name: "index_script_versions_on_script_code_id"
    t.index ["script_id"], name: "index_script_versions_on_script_id"
  end

  create_table "scripts", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "daily_installs", default: 0, null: false
    t.integer "total_installs", default: 0, null: false
    t.datetime "code_updated_at", precision: nil, null: false
    t.integer "sync_type"
    t.string "sync_identifier", limit: 500
    t.string "sync_error", limit: 1000
    t.datetime "last_attempted_sync_date", precision: nil
    t.datetime "last_successful_sync_date", precision: nil
    t.boolean "delta", default: true, null: false
    t.string "license_text", limit: 500
    t.integer "license_id"
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
    t.datetime "not_adult_content_self_report_date", precision: nil
    t.datetime "permanent_deletion_request_date", precision: nil
    t.boolean "promoted", default: false, null: false
    t.integer "promoted_script_id"
    t.boolean "adsense_approved"
    t.integer "page_views", default: 0, null: false
    t.boolean "has_syntax_error", default: false, null: false
    t.string "language", limit: 3, default: "js", null: false
    t.boolean "css_convertible_to_js", default: false, null: false
    t.boolean "not_js_convertible_override", default: false, null: false
    t.string "review_state", default: "not_required", null: false
    t.datetime "deleted_at", precision: nil
    t.datetime "consecutive_bad_ratings_at", precision: nil
    t.integer "marked_adult_by_user_id"
    t.boolean "self_deleted", default: false, null: false
    t.integer "sync_attempt_count", default: 0, null: false
    t.integer "delete_type"
    t.boolean "disable_stats", default: false, null: false
    t.boolean "pure_404", default: false, null: false
    t.boolean "missing_license_warned", default: false, null: false
    t.integer "script_type", default: 1, null: false
    t.integer "delete_report_id"
    t.text "deletion_message"
    t.index ["delete_type"], name: "index_scripts_on_delete_type"
    t.index ["delta"], name: "index_scripts_on_delta"
    t.index ["promoted"], name: "index_scripts_on_promoted"
    t.index ["promoted_script_id"], name: "fk_rails_f98f8b875c"
    t.index ["review_state"], name: "index_scripts_on_review_state"
  end

  create_table "sensitive_sites", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "domain", limit: 150, null: false
    t.index ["domain"], name: "index_sensitive_sites_on_domain", unique: true
  end

  create_table "site_applications", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "text", null: false
    t.boolean "blocked", default: false, null: false
    t.string "blocked_message"
    t.string "domain_text", limit: 100
    t.index ["domain_text"], name: "index_site_applications_on_domain_text", unique: true
  end

  create_table "spammy_email_domains", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "domain", limit: 20, null: false
    t.string "block_type", limit: 20, null: false
    t.index ["domain"], name: "index_spammy_email_domains_on_domain"
  end

  create_table "subresource_integrity_hashes", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "subresource_id", null: false
    t.string "algorithm", limit: 20, null: false
    t.string "encoding", limit: 10, null: false
    t.string "integrity_hash", limit: 128, null: false
    t.index ["subresource_id"], name: "index_subresource_integrity_hashes_on_subresource_id"
  end

  create_table "subresources", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "url", limit: 1024, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_attempt_at"
    t.datetime "last_success_at"
    t.datetime "last_change_at"
    t.index ["url"], name: "index_subresources_on_url", unique: true, using: :hash
  end

  create_table "syntax_highlighted_codes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.text "html", size: :medium, null: false
    t.index ["script_id"], name: "index_syntax_highlighted_codes_on_script_id"
  end

  create_table "test_update_counts", id: false, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.datetime "update_date", precision: nil, null: false
    t.string "ip", limit: 15, null: false
    t.index ["script_id", "ip"], name: "update_script_id_and_ip", unique: true
  end

  create_table "update_check_counts", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "script_id", null: false
    t.date "update_check_date", null: false
    t.integer "update_checks", null: false
    t.index ["script_id", "update_check_date"], name: "index_update_check_counts_on_script_id_and_update_check_date", unique: true
  end

  create_table "user_notification_settings", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "notification_type", null: false
    t.integer "delivery_type", null: false
    t.boolean "enabled", null: false
    t.index ["user_id", "notification_type"], name: "idx_on_user_id_notification_type_a388ca95c5"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "email", limit: 150, default: "", null: false
    t.string "encrypted_password", default: ""
    t.string "reset_password_token", limit: 150
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
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
    t.datetime "delete_confirmation_expiry", precision: nil
    t.string "confirmation_token", limit: 50
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.boolean "disposable_email"
    t.boolean "trusted_reports", default: false, null: false
    t.string "announcements_seen"
    t.string "canonical_email", null: false
    t.datetime "discussions_read_since", precision: nil
    t.boolean "subscribe_on_discussion", default: true, null: false
    t.boolean "subscribe_on_comment", default: true, null: false
    t.boolean "subscribe_on_conversation_starter", default: true, null: false
    t.boolean "subscribe_on_conversation_receiver", default: true, null: false
    t.datetime "banned_at", precision: nil
    t.string "email_domain", limit: 100
    t.string "session_token", limit: 32
    t.boolean "filter_locale_default", default: true, null: false
    t.boolean "notify_on_mention", default: false, null: false
    t.integer "stats_script_count", default: 0, null: false
    t.integer "stats_script_total_installs", default: 0, null: false
    t.integer "stats_script_daily_installs", default: 0, null: false
    t.decimal "stats_script_fan_score", precision: 6, scale: 1, default: "0.0", null: false
    t.integer "stats_script_ratings", default: 0, null: false
    t.datetime "stats_script_last_created", precision: nil
    t.datetime "stats_script_last_updated", precision: nil
    t.index ["canonical_email"], name: "index_users_on_canonical_email"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["email_domain", "current_sign_in_ip", "banned_at"], name: "index_users_on_email_domain_and_current_sign_in_ip_and_banned_at"
    t.index ["name"], name: "index_users_on_name", unique: true
    t.index ["remember_token"], name: "index_users_on_remember_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "antifeatures", "locales"
  add_foreign_key "antifeatures", "scripts", on_delete: :cascade
  add_foreign_key "authors", "scripts", on_delete: :cascade
  add_foreign_key "authors", "users", on_delete: :cascade
  add_foreign_key "blocked_script_codes", "scripts", column: "originating_script_id", on_delete: :cascade
  add_foreign_key "cleaned_codes", "scripts", on_delete: :cascade
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
  add_foreign_key "mentions", "users", on_delete: :cascade
  add_foreign_key "messages", "conversations", on_delete: :cascade
  add_foreign_key "moderator_actions", "reports", on_delete: :nullify
  add_foreign_key "notifications", "users", on_delete: :cascade
  add_foreign_key "reports", "users", column: "reporter_id", on_delete: :cascade
  add_foreign_key "roles_users", "users", on_delete: :cascade
  add_foreign_key "screenshots_script_versions", "script_versions", on_delete: :cascade
  add_foreign_key "script_applies_tos", "scripts", name: "fk_script_applies_tos_script_id"
  add_foreign_key "script_invitations", "scripts", on_delete: :cascade
  add_foreign_key "script_invitations", "users", column: "invited_user_id", on_delete: :cascade
  add_foreign_key "script_lock_appeals", "reports", on_delete: :cascade
  add_foreign_key "script_lock_appeals", "scripts", on_delete: :cascade
  add_foreign_key "script_sets", "users", on_delete: :cascade
  add_foreign_key "script_similarities", "scripts", column: "other_script_id", on_delete: :cascade
  add_foreign_key "script_similarities", "scripts", on_delete: :cascade
  add_foreign_key "script_versions", "scripts", name: "fk_script_versions_script_id"
  add_foreign_key "scripts", "scripts", column: "promoted_script_id", on_delete: :nullify
  add_foreign_key "user_notification_settings", "users", on_delete: :cascade
end
