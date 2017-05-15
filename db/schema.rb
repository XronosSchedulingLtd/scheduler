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

ActiveRecord::Schema.define(version: 20170515090847) do

  create_table "attachments", force: true do |t|
    t.string   "description"
    t.integer  "parent_id"
    t.string   "parent_type"
    t.string   "original_file_name"
    t.string   "meta_data"
    t.string   "saved_as"
    t.boolean  "visible_guest",      default: false
    t.boolean  "visible_staff",      default: false
    t.boolean  "visible_pupil",      default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "commitments", force: true do |t|
    t.integer  "event_id"
    t.integer  "element_id"
    t.integer  "covering_id"
    t.boolean  "names_event",         default: false
    t.integer  "source_id"
    t.boolean  "tentative",           default: false
    t.boolean  "rejected",            default: false
    t.boolean  "constraining",        default: false
    t.string   "reason",              default: ""
    t.integer  "by_whom_id"
    t.integer  "proto_commitment_id"
    t.integer  "request_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "commitments", ["constraining"], name: "index_commitments_on_constraining", using: :btree
  add_index "commitments", ["covering_id"], name: "index_commitments_on_covering_id", using: :btree
  add_index "commitments", ["element_id"], name: "index_commitments_on_element_id", using: :btree
  add_index "commitments", ["event_id"], name: "index_commitments_on_event_id", using: :btree
  add_index "commitments", ["proto_commitment_id"], name: "index_commitments_on_proto_commitment_id", using: :btree
  add_index "commitments", ["request_id"], name: "index_commitments_on_request_id", using: :btree
  add_index "commitments", ["tentative"], name: "index_commitments_on_tentative", using: :btree

  create_table "concerns", force: true do |t|
    t.integer  "user_id"
    t.integer  "element_id"
    t.boolean  "equality",         default: false, null: false
    t.boolean  "owns",             default: false, null: false
    t.boolean  "visible",          default: true,  null: false
    t.string   "colour",                           null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "auto_add",         default: false
    t.boolean  "controls",         default: false
    t.boolean  "skip_permissions", default: false
    t.boolean  "seek_permission",  default: false
  end

  add_index "concerns", ["element_id"], name: "index_concerns_on_element_id", using: :btree
  add_index "concerns", ["user_id"], name: "index_concerns_on_user_id", using: :btree

  create_table "datasources", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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
    t.boolean  "current",          default: false
    t.integer  "owner_id"
    t.string   "preferred_colour"
    t.boolean  "owned",            default: false
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
    t.string   "short_name", default: ""
  end

  create_table "eventcategories", force: true do |t|
    t.string   "name"
    t.integer  "pecking_order", default: 20
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
    t.boolean  "deprecated",    default: false
    t.boolean  "privileged",    default: false
    t.boolean  "visible",       default: true
    t.boolean  "clashcheck",    default: false
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
    t.text     "organiser_ref"
    t.boolean  "complete",         default: true
    t.boolean  "constrained",      default: false
    t.boolean  "has_clashes",      default: false
    t.integer  "proto_event_id"
    t.string   "flagcolour"
  end

  add_index "events", ["complete"], name: "index_events_on_complete", using: :btree
  add_index "events", ["ends_at"], name: "index_events_on_ends_at", using: :btree
  add_index "events", ["eventcategory_id"], name: "index_events_on_eventcategory_id", using: :btree
  add_index "events", ["has_clashes"], name: "index_events_on_has_clashes", using: :btree
  add_index "events", ["organiser_id"], name: "index_events_on_organiser_id", using: :btree
  add_index "events", ["owner_id"], name: "index_events_on_owner_id", using: :btree
  add_index "events", ["proto_event_id"], name: "index_events_on_proto_event_id", using: :btree
  add_index "events", ["source_hash"], name: "index_events_on_source_hash", using: :btree
  add_index "events", ["source_id"], name: "index_events_on_source_id", using: :btree
  add_index "events", ["starts_at"], name: "index_events_on_starts_at", using: :btree

  create_table "eventsources", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "exam_cycles", force: true do |t|
    t.string   "name"
    t.integer  "default_rota_template_id"
    t.date     "starts_on"
    t.date     "ends_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "default_group_element_id"
    t.integer  "default_quantity",         default: 5
  end

  create_table "freefinders", force: true do |t|
    t.integer  "element_id"
    t.string   "name"
    t.integer  "owner_id"
    t.date     "on"
    t.time     "start_time"
    t.time     "end_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "freefinders", ["owner_id"], name: "index_freefinders_on_owner_id", using: :btree

  create_table "groups", force: true do |t|
    t.date     "starts_on",                     null: false
    t.date     "ends_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "persona_id"
    t.string   "persona_type"
    t.string   "name"
    t.integer  "era_id"
    t.boolean  "current",       default: false
    t.integer  "owner_id"
    t.boolean  "make_public",   default: false
    t.integer  "source_id"
    t.string   "source_id_str"
    t.integer  "datasource_id"
  end

  add_index "groups", ["datasource_id"], name: "index_groups_on_datasource_id", using: :btree
  add_index "groups", ["era_id"], name: "index_groups_on_era_id", using: :btree
  add_index "groups", ["owner_id"], name: "index_groups_on_owner_id", using: :btree
  add_index "groups", ["source_id"], name: "index_groups_on_source_id", using: :btree
  add_index "groups", ["source_id_str"], name: "index_groups_on_source_id_str", using: :btree

  create_table "itemreports", force: true do |t|
    t.integer  "concern_id"
    t.boolean  "compact",             default: false
    t.boolean  "duration",            default: false
    t.boolean  "mark_end",            default: false
    t.boolean  "locations",           default: false
    t.boolean  "staff",               default: false
    t.boolean  "pupils",              default: false
    t.boolean  "periods",             default: false
    t.date     "starts_on"
    t.date     "ends_on"
    t.boolean  "twelve_hour",         default: false
    t.boolean  "end_time",            default: true
    t.boolean  "breaks",              default: false
    t.boolean  "suppress_empties",    default: false
    t.boolean  "tentative",           default: false
    t.boolean  "firm",                default: false
    t.string   "categories",          default: ""
    t.integer  "excluded_element_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "notes",               default: false
    t.string   "note_flags",          default: ""
    t.boolean  "no_space",            default: false
    t.boolean  "enddot",              default: true
  end

  add_index "itemreports", ["concern_id"], name: "index_itemreports_on_concern_id", using: :btree

  create_table "locationaliases", force: true do |t|
    t.string   "name"
    t.integer  "source_id"
    t.integer  "location_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "display",       default: false
    t.boolean  "friendly",      default: false
    t.integer  "datasource_id"
  end

  add_index "locationaliases", ["location_id"], name: "index_locationaliases_on_location_id", using: :btree

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

  create_table "notes", force: true do |t|
    t.string   "title",         default: ""
    t.text     "contents"
    t.integer  "parent_id"
    t.string   "parent_type"
    t.integer  "owner_id"
    t.integer  "promptnote_id"
    t.boolean  "visible_guest", default: false
    t.boolean  "visible_staff", default: true
    t.boolean  "visible_pupil", default: false
    t.integer  "note_type",     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notes", ["owner_id"], name: "index_notes_on_owner_id", using: :btree
  add_index "notes", ["parent_id"], name: "index_notes_on_parent_id", using: :btree

  create_table "otherhalfgrouppersonae", force: true do |t|
    t.integer  "source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "otherhalfgrouppersonae", ["source_id"], name: "index_otherhalfgrouppersonae_on_source_id", using: :btree

  create_table "promptnotes", force: true do |t|
    t.string   "title",            default: ""
    t.text     "prompt"
    t.text     "default_contents"
    t.integer  "element_id"
    t.boolean  "read_only",        default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "promptnotes", ["element_id"], name: "index_promptnotes_on_element_id", using: :btree

  create_table "properties", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "make_public", default: false
  end

  create_table "proto_commitments", force: true do |t|
    t.integer  "proto_event_id"
    t.integer  "element_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "proto_commitments", ["element_id"], name: "index_proto_commitments_on_element_id", using: :btree
  add_index "proto_commitments", ["proto_event_id"], name: "index_proto_commitments_on_proto_event_id", using: :btree

  create_table "proto_events", force: true do |t|
    t.text     "body"
    t.date     "starts_on"
    t.date     "ends_on"
    t.integer  "eventcategory_id"
    t.integer  "eventsource_id"
    t.integer  "rota_template_id"
    t.integer  "generator_id"
    t.string   "generator_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "proto_events", ["eventcategory_id"], name: "index_proto_events_on_eventcategory_id", using: :btree
  add_index "proto_events", ["eventsource_id"], name: "index_proto_events_on_eventsource_id", using: :btree
  add_index "proto_events", ["generator_id", "generator_type"], name: "index_proto_events_on_generator_id_and_generator_type", using: :btree
  add_index "proto_events", ["rota_template_id"], name: "index_proto_events_on_rota_template_id", using: :btree

  create_table "proto_requests", force: true do |t|
    t.integer  "proto_event_id"
    t.integer  "element_id"
    t.integer  "quantity"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "proto_requests", ["element_id"], name: "index_proto_requests_on_element_id", using: :btree
  add_index "proto_requests", ["proto_event_id"], name: "index_proto_requests_on_proto_event_id", using: :btree

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
    t.boolean  "current",       default: false
    t.integer  "datasource_id"
  end

  add_index "pupils", ["datasource_id"], name: "index_pupils_on_datasource_id", using: :btree
  add_index "pupils", ["source_id"], name: "index_pupils_on_source_id", using: :btree

  create_table "requests", force: true do |t|
    t.integer  "event_id"
    t.integer  "element_id"
    t.integer  "proto_request_id"
    t.integer  "quantity",         default: 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "requests", ["element_id"], name: "index_requests_on_element_id", using: :btree
  add_index "requests", ["event_id"], name: "index_requests_on_event_id", using: :btree
  add_index "requests", ["proto_request_id"], name: "index_requests_on_proto_request_id", using: :btree

  create_table "rota_slots", force: true do |t|
    t.integer  "rota_template_id"
    t.time     "starts_at"
    t.time     "ends_at"
    t.text     "days"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rota_slots", ["rota_template_id"], name: "index_rota_slots_on_rota_template_id", using: :btree

  create_table "rota_templates", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "services", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "settings", force: true do |t|
    t.integer  "current_era_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "next_era_id"
    t.integer  "previous_era_id"
    t.integer  "perpetual_era_id"
    t.boolean  "enforce_permissions", default: false
    t.string   "current_mis"
    t.string   "previous_mis"
    t.integer  "auth_type",           default: 0
    t.string   "dns_domain_name",     default: ""
    t.string   "from_email_address",  default: ""
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
    t.boolean  "current",       default: false
    t.boolean  "teaches"
    t.boolean  "does_cover"
    t.integer  "datasource_id"
    t.boolean  "multicover",    default: false
  end

  add_index "staffs", ["datasource_id"], name: "index_staffs_on_datasource_id", using: :btree
  add_index "staffs", ["source_id"], name: "index_staffs_on_source_id", using: :btree

  create_table "staffs_subjects", id: false, force: true do |t|
    t.integer "staff_id"
    t.integer "subject_id"
  end

  add_index "staffs_subjects", ["staff_id"], name: "index_staffs_subjects_on_staff_id", using: :btree
  add_index "staffs_subjects", ["subject_id"], name: "index_staffs_subjects_on_subject_id", using: :btree

  create_table "staffs_teachinggrouppersonae", id: false, force: true do |t|
    t.integer "staff_id"
    t.integer "teachinggrouppersona_id"
  end

  add_index "staffs_teachinggrouppersonae", ["staff_id"], name: "index_staffs_teachinggrouppersonae_on_staff_id", using: :btree
  add_index "staffs_teachinggrouppersonae", ["teachinggrouppersona_id"], name: "index_staffs_teachinggrouppersonae_on_teachinggrouppersona_id", using: :btree

  create_table "subjects", force: true do |t|
    t.string   "name"
    t.boolean  "current",       default: true
    t.integer  "datasource_id"
    t.integer  "source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "taggrouppersonae", force: true do |t|
    t.integer  "source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "taggrouppersonae", ["source_id"], name: "index_taggrouppersonae_on_source_id", using: :btree

  create_table "teachinggrouppersonae", force: true do |t|
    t.integer  "source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "subject_id"
    t.integer  "yeargroup"
  end

  add_index "teachinggrouppersonae", ["source_id"], name: "index_teachinggrouppersonae_on_source_id", using: :btree
  add_index "teachinggrouppersonae", ["subject_id"], name: "index_teachinggrouppersonae_on_subject_id", using: :btree

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
    t.boolean  "show_owned",                  default: true
    t.boolean  "privileged",                  default: false
    t.integer  "firstday",                    default: 0
    t.string   "default_event_text",          default: ""
    t.boolean  "public_groups",               default: false
    t.boolean  "element_owner",               default: false
    t.boolean  "email_notification",          default: true
    t.boolean  "can_has_groups",              default: false
    t.boolean  "can_find_free",               default: false
    t.boolean  "can_add_concerns",            default: false
    t.boolean  "can_su",                      default: false
    t.boolean  "immediate_notification",      default: false
    t.boolean  "can_roam",                    default: false
    t.boolean  "clash_weekly",                default: false
    t.boolean  "clash_daily",                 default: false
    t.boolean  "clash_immediate",             default: false
    t.boolean  "edit_all_events",             default: false
    t.boolean  "subedit_all_events",          default: false
    t.boolean  "exams",                       default: false
    t.boolean  "invig_weekly",                default: true
    t.boolean  "invig_daily",                 default: true
    t.date     "last_invig_run_date"
  end

end
