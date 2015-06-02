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

ActiveRecord::Schema.define(version: 20150601193106) do

  create_table "commitments", force: true do |t|
    t.integer "event_id"
    t.integer "element_id"
    t.integer "covering_id"
    t.boolean "names_event", default: false
    t.integer "source_id"
  end

  add_index "commitments", ["covering_id"], name: "index_commitments_on_covering_id", using: :btree
  add_index "commitments", ["element_id"], name: "index_commitments_on_element_id", using: :btree
  add_index "commitments", ["event_id"], name: "index_commitments_on_event_id", using: :btree

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "elements", force: true do |t|
    t.string   "name"
    t.integer  "entity_id"
    t.string   "entity_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "current",     default: false
    t.integer  "owner_id"
  end

  add_index "elements", ["entity_id"], name: "index_elements_on_entity_id", using: :btree
  add_index "elements", ["owner_id"], name: "index_elements_on_owner_id", using: :btree

  create_table "eras", force: true do |t|
    t.string   "name"
    t.date     "starts_on"
    t.date     "ends_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "source_id"
  end

  create_table "eventcategories", force: true do |t|
    t.string   "name"
    t.integer  "pecking_order"
    t.boolean  "schoolwide"
    t.boolean  "publish"
    t.boolean  "public"
    t.boolean  "for_users"
    t.boolean  "unimportant"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "can_merge",     default: false
    t.boolean  "can_borrow",    default: false
    t.boolean  "compactable",   default: true
  end

  create_table "events", force: true do |t|
    t.text     "body"
    t.integer  "eventcategory_id",                 null: false
    t.integer  "eventsource_id",                   null: false
    t.integer  "owner_id"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.boolean  "approximate",      default: false
    t.boolean  "non_existent",     default: false
    t.boolean  "private",          default: false
    t.integer  "reference_id"
    t.string   "reference_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "all_day",          default: false
    t.boolean  "compound",         default: false
    t.integer  "source_id",        default: 0
    t.string   "source_hash"
    t.integer  "organiser_id"
  end

  add_index "events", ["ends_at"], name: "index_events_on_ends_at", using: :btree
  add_index "events", ["eventcategory_id"], name: "index_events_on_eventcategory_id", using: :btree
  add_index "events", ["owner_id"], name: "index_events_on_owner_id", using: :btree
  add_index "events", ["source_id"], name: "index_events_on_source_id", using: :btree
  add_index "events", ["starts_at"], name: "index_events_on_starts_at", using: :btree

  create_table "eventsources", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups", force: true do |t|
    t.date     "starts_on",                    null: false
    t.date     "ends_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "persona_id"
    t.string   "persona_type"
    t.string   "name"
    t.integer  "era_id"
    t.boolean  "current",      default: false
    t.integer  "owner_id"
  end

  add_index "groups", ["era_id"], name: "index_groups_on_era_id", using: :btree
  add_index "groups", ["owner_id"], name: "index_groups_on_owner_id", using: :btree

  create_table "interests", force: true do |t|
    t.integer  "user_id"
    t.integer  "element_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "colour",     default: "gray"
    t.boolean  "visible",    default: true
  end

  add_index "interests", ["element_id"], name: "index_interests_on_element_id", using: :btree
  add_index "interests", ["user_id"], name: "index_interests_on_user_id", using: :btree

  create_table "locationaliases", force: true do |t|
    t.string   "name"
    t.integer  "source_id"
    t.integer  "location_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "display",     default: false
    t.boolean  "friendly",    default: false
  end

  create_table "locations", force: true do |t|
    t.string   "name"
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "current",    default: false
  end

  create_table "memberships", force: true do |t|
    t.integer  "group_id",   null: false
    t.integer  "element_id", null: false
    t.date     "starts_on",  null: false
    t.date     "ends_on"
    t.date     "as_at"
    t.boolean  "inverse",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "role_id"
  end

  add_index "memberships", ["element_id"], name: "index_memberships_on_element_id", using: :btree
  add_index "memberships", ["group_id"], name: "index_memberships_on_group_id", using: :btree

  create_table "ownerships", force: true do |t|
    t.integer  "user_id"
    t.integer  "element_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "equality",   default: false
    t.string   "colour",     default: "#225599"
  end

  create_table "properties", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pupils", force: true do |t|
    t.string   "name"
    t.string   "surname"
    t.string   "forename"
    t.string   "known_as"
    t.string   "email"
    t.string   "candidate_no"
    t.integer  "start_year"
    t.integer  "source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "current",      default: false
  end

  add_index "pupils", ["source_id"], name: "index_pupils_on_source_id", using: :btree

  create_table "services", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "settings", force: true do |t|
    t.integer  "current_era_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "staffs", force: true do |t|
    t.string   "name"
    t.string   "initials"
    t.string   "surname"
    t.string   "title"
    t.string   "forename"
    t.string   "email"
    t.integer  "source_id"
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "current",    default: false
    t.boolean  "teaches"
    t.boolean  "does_cover"
  end

  add_index "staffs", ["source_id"], name: "index_staffs_on_source_id", using: :btree

  create_table "teachinggrouppersonae", force: true do |t|
    t.integer  "source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "teachinggrouppersonae", ["source_id"], name: "index_teachinggrouppersonae_on_source_id", using: :btree

  create_table "tutorgrouppersonae", force: true do |t|
    t.string   "house"
    t.integer  "staff_id"
    t.integer  "start_year"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "provider"
    t.string   "uid"
    t.string   "name"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "admin",                       default: false
    t.boolean  "editor",                      default: false
    t.string   "colour_involved",             default: "#234B58"
    t.string   "colour_not_involved",         default: "#254117"
    t.boolean  "arranges_cover",              default: false
    t.integer  "preferred_event_category_id"
    t.boolean  "secretary",                   default: false
  end

end
