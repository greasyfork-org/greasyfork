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

ActiveRecord::Schema.define(version: 20140224024436) do

  create_table "allowed_requires", force: true do |t|
    t.string   "pattern",                null: false
    t.string   "name",                   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url",        limit: 500
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
    t.integer  "script_id",                        null: false
    t.text     "changelog"
    t.text     "additional_info"
    t.text     "version",                          null: false
    t.text     "code",            limit: 16777215, null: false
    t.text     "rewritten_code",  limit: 16777215, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "script_versions", ["script_id"], name: "index_script_versions_on_script_id", using: :btree

  create_table "scripts", force: true do |t|
    t.string   "name",            limit: 100,             null: false
    t.text     "description",                             null: false
    t.text     "additional_info"
    t.integer  "user_id",                                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "userscripts_id"
    t.integer  "daily_installs",              default: 0, null: false
    t.integer  "total_installs",              default: 0, null: false
  end

  add_index "scripts", ["user_id"], name: "index_scripts_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                                default: "", null: false
    t.string   "encrypted_password",                   default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                        default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                   limit: 50,                 null: false
    t.string   "profile",                limit: 10000
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
