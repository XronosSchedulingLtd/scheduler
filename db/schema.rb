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

ActiveRecord::Schema.define(version: 20191101132537) do

  create_table "ahoy_messages", force: :cascade do |t|
    t.integer  "user_id",   limit: 4
    t.string   "user_type", limit: 255
    t.text     "to",        limit: 65535
    t.string   "mailer",    limit: 255
    t.text     "subject",   limit: 65535
    t.text     "content",   limit: 16777215
    t.datetime "sent_at"
  end

  add_index "ahoy_messages", ["user_type", "user_id"], name: "index_ahoy_messages_on_user_type_and_user_id", using: :btree

  create_table "attachments", force: :cascade do |t|
    t.integer  "parent_id",    limit: 4
    t.string   "parent_type",  limit: 255
    t.integer  "user_file_id", limit: 4
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "attachments", ["parent_id", "parent_type"], name: "index_attachments_on_parent_id_and_parent_type", using: :btree
  add_index "attachments", ["user_file_id"], name: "index_attachments_on_user_file_id", using: :btree

  create_table "comments", force: :cascade do |t|
    t.integer  "parent_id",   limit: 4
    t.string   "parent_type", limit: 255
    t.integer  "user_id",     limit: 4
    t.text     "body",        limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["parent_type", "parent_id"], name: "index_comments_on_parent_type_and_parent_id", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "commitments", force: :cascade do |t|
    t.integer  "event_id",            limit: 4
    t.integer  "element_id",          limit: 4
    t.integer  "covering_id",         limit: 4
    t.boolean  "names_event",                     default: false
    t.integer  "source_id",           limit: 4
    t.boolean  "tentative",                       default: false
    t.string   "reason",              limit: 255, default: ""
    t.integer  "by_whom_id",          limit: 4
    t.integer  "proto_commitment_id", limit: 4
    t.integer  "request_id",          limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",              limit: 4,   default: 0
  end

  add_index "commitments", ["by_whom_id"], name: "index_commitments_on_by_whom_id", using: :btree
  add_index "commitments", ["covering_id"], name: "index_commitments_on_covering_id", using: :btree
  add_index "commitments", ["element_id"], name: "index_commitments_on_element_id", using: :btree
  add_index "commitments", ["event_id"], name: "index_commitments_on_event_id", using: :btree
  add_index "commitments", ["proto_commitment_id"], name: "index_commitments_on_proto_commitment_id", using: :btree
  add_index "commitments", ["request_id"], name: "index_commitments_on_request_id", using: :btree
  add_index "commitments", ["status"], name: "index_commitments_on_status", using: :btree
  add_index "commitments", ["tentative"], name: "index_commitments_on_tentative", using: :btree

  create_table "concern_sets", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "owner_id",   limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "concerns", force: :cascade do |t|
    t.integer  "user_id",          limit: 4
    t.integer  "element_id",       limit: 4
    t.boolean  "equality",                     default: false, null: false
    t.boolean  "owns",                         default: false, null: false
    t.boolean  "visible",                      default: true,  null: false
    t.string   "colour",           limit: 255,                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "auto_add",                     default: false
    t.boolean  "edit_any",                     default: false
    t.boolean  "skip_permissions",             default: false
    t.boolean  "seek_permission",              default: false
    t.boolean  "list_teachers",                default: false
    t.boolean  "subedit_any",                  default: false
    t.integer  "concern_set_id",   limit: 4
    t.boolean  "assistant_to",                 default: false
  end

  add_index "concerns", ["element_id"], name: "index_concerns_on_element_id", using: :btree
  add_index "concerns", ["user_id"], name: "index_concerns_on_user_id", using: :btree

  create_table "datasources", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0, null: false
    t.integer  "attempts",   limit: 4,     default: 0, null: false
    t.text     "handler",    limit: 65535,             null: false
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "elements", force: :cascade do |t|
    t.string   "name",             limit: 255
    t.integer  "entity_id",        limit: 4
    t.string   "entity_type",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "current",                      default: false
    t.integer  "owner_id",         limit: 4
    t.string   "preferred_colour", limit: 255
    t.boolean  "owned",                        default: false
    t.string   "uuid",             limit: 255
    t.integer  "user_form_id",     limit: 4
    t.boolean  "add_directly",                 default: true
    t.boolean  "viewable",                     default: true
  end

  add_index "elements", ["entity_id"], name: "index_elements_on_entity_id", using: :btree
  add_index "elements", ["entity_type", "entity_id"], name: "index_elements_on_entity_type_and_entity_id", using: :btree
  add_index "elements", ["owner_id"], name: "index_elements_on_owner_id", using: :btree
  add_index "elements", ["uuid"], name: "index_elements_on_uuid", unique: true, using: :btree

  create_table "eras", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.date     "starts_on"
    t.date     "ends_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "source_id",  limit: 4
    t.string   "short_name", limit: 255, default: ""
  end

  create_table "event_collections", force: :cascade do |t|
    t.integer  "era_id",                limit: 4
    t.date     "repetition_start_date"
    t.date     "repetition_end_date"
    t.string   "days_of_week",          limit: 255
    t.string   "weeks",                 limit: 255
    t.integer  "when_in_month",         limit: 4,   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "update_requested_at"
    t.datetime "update_started_at"
    t.datetime "update_finished_at"
    t.integer  "lock_version",          limit: 4,   default: 0,     null: false
    t.integer  "requesting_user_id",    limit: 4
    t.boolean  "preserve_earlier",                  default: false
    t.boolean  "preserve_later",                    default: false
    t.boolean  "preserve_historical",               default: true
  end

  add_index "event_collections", ["requesting_user_id"], name: "index_event_collections_on_requesting_user_id", using: :btree

  create_table "eventcategories", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.integer  "pecking_order", limit: 4,   default: 20
    t.boolean  "schoolwide"
    t.boolean  "publish"
    t.boolean  "public"
    t.boolean  "for_users"
    t.boolean  "unimportant"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "can_merge",                 default: false
    t.boolean  "can_borrow",                default: false
    t.boolean  "compactable",               default: true
    t.boolean  "deprecated",                default: false
    t.boolean  "privileged",                default: false
    t.boolean  "visible",                   default: true
    t.boolean  "clashcheck",                default: false
    t.boolean  "busy",                      default: true
    t.boolean  "timetable",                 default: false
    t.boolean  "confidential",              default: false
  end

  create_table "events", force: :cascade do |t|
    t.text     "body",                limit: 65535
    t.integer  "eventcategory_id",    limit: 4,                     null: false
    t.integer  "eventsource_id",      limit: 4,                     null: false
    t.integer  "owner_id",            limit: 4
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.boolean  "approximate",                       default: false
    t.boolean  "non_existent",                      default: false
    t.boolean  "private",                           default: false
    t.integer  "reference_id",        limit: 4
    t.string   "reference_type",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "all_day",                           default: false
    t.boolean  "compound",                          default: false
    t.integer  "source_id",           limit: 4,     default: 0
    t.string   "source_hash",         limit: 255
    t.integer  "organiser_id",        limit: 4
    t.text     "organiser_ref",       limit: 65535
    t.boolean  "complete",                          default: true
    t.boolean  "constrained",                       default: false
    t.boolean  "has_clashes",                       default: false
    t.integer  "proto_event_id",      limit: 4
    t.string   "flagcolour",          limit: 255
    t.integer  "event_collection_id", limit: 4
    t.boolean  "confidential",                      default: false
  end

  add_index "events", ["complete"], name: "index_events_on_complete", using: :btree
  add_index "events", ["ends_at"], name: "index_events_on_ends_at", using: :btree
  add_index "events", ["event_collection_id"], name: "index_events_on_event_collection_id", using: :btree
  add_index "events", ["eventcategory_id"], name: "index_events_on_eventcategory_id", using: :btree
  add_index "events", ["has_clashes"], name: "index_events_on_has_clashes", using: :btree
  add_index "events", ["organiser_id"], name: "index_events_on_organiser_id", using: :btree
  add_index "events", ["owner_id"], name: "index_events_on_owner_id", using: :btree
  add_index "events", ["proto_event_id"], name: "index_events_on_proto_event_id", using: :btree
  add_index "events", ["source_hash"], name: "index_events_on_source_hash", using: :btree
  add_index "events", ["source_id"], name: "index_events_on_source_id", using: :btree
  add_index "events", ["starts_at"], name: "index_events_on_starts_at", using: :btree

  create_table "eventsources", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "exam_cycles", force: :cascade do |t|
    t.string   "name",                     limit: 255
    t.integer  "default_rota_template_id", limit: 4
    t.date     "starts_on"
    t.date     "ends_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "default_group_element_id", limit: 4
    t.integer  "default_quantity",         limit: 4,   default: 5
    t.integer  "selector_element_id",      limit: 4
  end

  create_table "freefinders", force: :cascade do |t|
    t.integer  "element_id", limit: 4
    t.string   "name",       limit: 255
    t.integer  "owner_id",   limit: 4
    t.date     "on"
    t.time     "start_time"
    t.time     "end_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "freefinders", ["owner_id"], name: "index_freefinders_on_owner_id", using: :btree

  create_table "groups", force: :cascade do |t|
    t.date     "starts_on",                                 null: false
    t.date     "ends_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "persona_id",    limit: 4
    t.string   "persona_type",  limit: 255
    t.string   "name",          limit: 255
    t.integer  "era_id",        limit: 4
    t.boolean  "current",                   default: false
    t.integer  "owner_id",      limit: 4
    t.boolean  "make_public",               default: false
    t.integer  "source_id",     limit: 4
    t.string   "source_id_str", limit: 255
    t.integer  "datasource_id", limit: 4
  end

  add_index "groups", ["datasource_id"], name: "index_groups_on_datasource_id", using: :btree
  add_index "groups", ["era_id"], name: "index_groups_on_era_id", using: :btree
  add_index "groups", ["owner_id"], name: "index_groups_on_owner_id", using: :btree
  add_index "groups", ["persona_type", "persona_id"], name: "index_groups_on_persona_type_and_persona_id", using: :btree
  add_index "groups", ["source_id"], name: "index_groups_on_source_id", using: :btree
  add_index "groups", ["source_id_str"], name: "index_groups_on_source_id_str", using: :btree

  create_table "itemreports", force: :cascade do |t|
    t.integer  "concern_id",          limit: 4
    t.boolean  "compact",                         default: false
    t.boolean  "duration",                        default: false
    t.boolean  "mark_end",                        default: false
    t.boolean  "locations",                       default: false
    t.boolean  "staff",                           default: false
    t.boolean  "pupils",                          default: false
    t.boolean  "periods",                         default: false
    t.date     "starts_on"
    t.date     "ends_on"
    t.boolean  "twelve_hour",                     default: false
    t.boolean  "end_time",                        default: true
    t.boolean  "breaks",                          default: false
    t.boolean  "suppress_empties",                default: false
    t.boolean  "tentative",                       default: false
    t.boolean  "firm",                            default: false
    t.string   "categories",          limit: 255, default: ""
    t.integer  "excluded_element_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "notes",                           default: false
    t.string   "note_flags",          limit: 255, default: ""
    t.boolean  "no_space",                        default: false
    t.boolean  "enddot",                          default: true
  end

  add_index "itemreports", ["concern_id"], name: "index_itemreports_on_concern_id", using: :btree

  create_table "journal_entries", force: :cascade do |t|
    t.integer  "journal_id",      limit: 4
    t.integer  "user_id",         limit: 4
    t.integer  "entry_type",      limit: 4
    t.text     "details",         limit: 65535
    t.integer  "element_id",      limit: 4
    t.datetime "event_starts_at"
    t.datetime "event_ends_at"
    t.boolean  "event_all_day"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "repeating",                     default: false
  end

  add_index "journal_entries", ["element_id"], name: "index_journal_entries_on_element_id", using: :btree
  add_index "journal_entries", ["journal_id"], name: "index_journal_entries_on_journal_id", using: :btree
  add_index "journal_entries", ["user_id"], name: "index_journal_entries_on_user_id", using: :btree

  create_table "journals", force: :cascade do |t|
    t.integer  "event_id",               limit: 4
    t.text     "event_body",             limit: 65535
    t.integer  "event_eventcategory_id", limit: 4
    t.integer  "event_owner_id",         limit: 4
    t.datetime "event_starts_at"
    t.datetime "event_ends_at"
    t.boolean  "event_all_day"
    t.integer  "event_organiser_id",     limit: 4
    t.text     "event_organiser_ref",    limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "journals", ["event_id"], name: "index_journals_on_event_id", using: :btree

  create_table "locationaliases", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.integer  "source_id",     limit: 4
    t.integer  "location_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "display",                   default: false
    t.boolean  "friendly",                  default: false
    t.integer  "datasource_id", limit: 4
  end

  add_index "locationaliases", ["location_id"], name: "index_locationaliases_on_location_id", using: :btree

  create_table "locations", force: :cascade do |t|
    t.string   "name",             limit: 255
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "current",                      default: false
    t.integer  "num_invigilators", limit: 4,   default: 1
  end

  create_table "memberships", force: :cascade do |t|
    t.integer  "group_id",   limit: 4, null: false
    t.integer  "element_id", limit: 4, null: false
    t.date     "starts_on",            null: false
    t.date     "ends_on"
    t.boolean  "inverse",              null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "memberships", ["element_id"], name: "index_memberships_on_element_id", using: :btree
  add_index "memberships", ["group_id"], name: "index_memberships_on_group_id", using: :btree

  create_table "notes", force: :cascade do |t|
    t.string   "title",              limit: 255,   default: ""
    t.text     "contents",           limit: 65535
    t.integer  "parent_id",          limit: 4
    t.string   "parent_type",        limit: 255
    t.integer  "owner_id",           limit: 4
    t.integer  "promptnote_id",      limit: 4
    t.boolean  "visible_guest",                    default: false
    t.boolean  "visible_staff",                    default: true
    t.boolean  "visible_pupil",                    default: false
    t.integer  "note_type",          limit: 4,     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "formatted_contents", limit: 65535
  end

  add_index "notes", ["owner_id"], name: "index_notes_on_owner_id", using: :btree
  add_index "notes", ["parent_id"], name: "index_notes_on_parent_id", using: :btree
  add_index "notes", ["parent_type", "parent_id"], name: "index_notes_on_parent_type_and_parent_id", using: :btree

  create_table "otherhalfgrouppersonae", force: :cascade do |t|
    t.integer  "source_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "otherhalfgrouppersonae", ["source_id"], name: "index_otherhalfgrouppersonae_on_source_id", using: :btree

  create_table "pre_requisites", force: :cascade do |t|
    t.string   "label",        limit: 255
    t.text     "description",  limit: 65535
    t.integer  "element_id",   limit: 4
    t.integer  "priority",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "pre_creation",               default: true
    t.boolean  "quick_button",               default: true
  end

  create_table "promptnotes", force: :cascade do |t|
    t.string   "title",            limit: 255,   default: ""
    t.text     "prompt",           limit: 65535
    t.text     "default_contents", limit: 65535
    t.integer  "element_id",       limit: 4
    t.boolean  "read_only",                      default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "promptnotes", ["element_id"], name: "index_promptnotes_on_element_id", using: :btree

  create_table "properties", force: :cascade do |t|
    t.string   "name",             limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "make_public",                  default: false
    t.boolean  "auto_staff",                   default: false
    t.boolean  "auto_pupils",                  default: false
    t.boolean  "current",                      default: true
    t.boolean  "feed_as_category",             default: false
  end

  create_table "proto_commitments", force: :cascade do |t|
    t.integer  "proto_event_id", limit: 4
    t.integer  "element_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "proto_commitments", ["element_id"], name: "index_proto_commitments_on_element_id", using: :btree
  add_index "proto_commitments", ["proto_event_id"], name: "index_proto_commitments_on_proto_event_id", using: :btree

  create_table "proto_events", force: :cascade do |t|
    t.text     "body",             limit: 65535
    t.date     "starts_on"
    t.date     "ends_on"
    t.integer  "eventcategory_id", limit: 4
    t.integer  "eventsource_id",   limit: 4
    t.integer  "rota_template_id", limit: 4
    t.integer  "generator_id",     limit: 4
    t.string   "generator_type",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "proto_events", ["eventcategory_id"], name: "index_proto_events_on_eventcategory_id", using: :btree
  add_index "proto_events", ["eventsource_id"], name: "index_proto_events_on_eventsource_id", using: :btree
  add_index "proto_events", ["generator_id", "generator_type"], name: "index_proto_events_on_generator_id_and_generator_type", using: :btree
  add_index "proto_events", ["rota_template_id"], name: "index_proto_events_on_rota_template_id", using: :btree

  create_table "proto_requests", force: :cascade do |t|
    t.integer  "proto_event_id", limit: 4
    t.integer  "element_id",     limit: 4
    t.integer  "quantity",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "proto_requests", ["element_id"], name: "index_proto_requests_on_element_id", using: :btree
  add_index "proto_requests", ["proto_event_id"], name: "index_proto_requests_on_proto_event_id", using: :btree

  create_table "pupils", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.string   "surname",       limit: 255
    t.string   "forename",      limit: 255
    t.string   "known_as",      limit: 255
    t.string   "email",         limit: 255
    t.string   "candidate_no",  limit: 255
    t.integer  "start_year",    limit: 4
    t.integer  "source_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "current",                   default: false
    t.integer  "datasource_id", limit: 4
    t.string   "house_name",    limit: 255, default: ""
  end

  add_index "pupils", ["datasource_id"], name: "index_pupils_on_datasource_id", using: :btree
  add_index "pupils", ["source_id"], name: "index_pupils_on_source_id", using: :btree

  create_table "requests", force: :cascade do |t|
    t.integer  "event_id",          limit: 4
    t.integer  "element_id",        limit: 4
    t.integer  "proto_request_id",  limit: 4
    t.integer  "quantity",          limit: 4, default: 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "tentative",                   default: true
    t.boolean  "constraining",                default: false
    t.boolean  "reconfirmed",                 default: false
    t.integer  "commitments_count", limit: 4, default: 0,     null: false
  end

  add_index "requests", ["element_id"], name: "index_requests_on_element_id", using: :btree
  add_index "requests", ["event_id"], name: "index_requests_on_event_id", using: :btree
  add_index "requests", ["proto_request_id"], name: "index_requests_on_proto_request_id", using: :btree

  create_table "resourcegrouppersonae", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "loading_report_days", limit: 4, default: 0
    t.integer  "wrapping_mins",       limit: 4, default: 0
    t.integer  "confirmation_days",   limit: 4, default: 0
    t.integer  "form_warning_days",   limit: 4, default: 0
    t.boolean  "needs_people",                  default: false
  end

  create_table "rota_slots", force: :cascade do |t|
    t.integer  "rota_template_id", limit: 4
    t.time     "starts_at"
    t.time     "ends_at"
    t.text     "days",             limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rota_slots", ["rota_template_id"], name: "index_rota_slots_on_rota_template_id", using: :btree

  create_table "rota_template_types", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rota_templates", force: :cascade do |t|
    t.string   "name",                  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "rota_template_type_id", limit: 4
    t.integer  "owner_id",              limit: 4
    t.string   "owner_type",            limit: 255
  end

  create_table "services", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "current",                  default: true
    t.boolean  "add_directly",             default: true
  end

  create_table "settings", force: :cascade do |t|
    t.integer  "current_era_id",                   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "next_era_id",                      limit: 4
    t.integer  "previous_era_id",                  limit: 4
    t.integer  "perpetual_era_id",                 limit: 4
    t.boolean  "enforce_permissions",                            default: false
    t.string   "current_mis",                      limit: 255
    t.string   "previous_mis",                     limit: 255
    t.integer  "auth_type",                        limit: 4,     default: 0
    t.string   "dns_domain_name",                  limit: 255,   default: ""
    t.string   "from_email_address",               limit: 255,   default: ""
    t.boolean  "prefer_https",                                   default: true
    t.boolean  "require_uuid",                                   default: false
    t.integer  "room_cover_group_element_id",      limit: 4
    t.text     "event_creation_markup",            limit: 65535
    t.text     "event_creation_html",              limit: 65535
    t.integer  "wrapping_before_mins",             limit: 4,     default: 60
    t.integer  "wrapping_after_mins",              limit: 4,     default: 30
    t.integer  "wrapping_eventcategory_id",        limit: 4
    t.integer  "default_display_day_shape_id",     limit: 4
    t.integer  "default_free_finder_day_shape_id", limit: 4
    t.string   "title_text",                       limit: 255
    t.string   "public_title_text",                limit: 255
    t.boolean  "tutorgroups_by_house",                           default: true
    t.string   "tutorgroups_name",                 limit: 255,   default: "Tutor group"
    t.string   "tutor_name",                       limit: 255,   default: "Tutor"
    t.string   "prep_suffix",                      limit: 255,   default: "(P)"
    t.integer  "prep_property_element_id",         limit: 4
    t.boolean  "ordinalize_years",                               default: true
    t.integer  "max_quick_buttons",                limit: 4,     default: 0
    t.integer  "first_tt_day",                     limit: 4,     default: 1
    t.integer  "last_tt_day",                      limit: 4,     default: 5
    t.integer  "tt_cycle_weeks",                   limit: 4,     default: 2
    t.string   "tt_prep_letter",                   limit: 2,     default: "P"
    t.date     "tt_store_start",                                 default: '2006-01-01'
    t.string   "busy_string",                      limit: 255,   default: "Busy"
    t.string   "user_files_dir",                   limit: 255,   default: "UserFiles"
    t.integer  "user_file_allowance",              limit: 4,     default: 0
    t.integer  "email_keep_days",                  limit: 4,     default: 0
    t.integer  "event_keep_years",                 limit: 4,     default: 0
  end

  create_table "staffs", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.string   "initials",      limit: 255
    t.string   "surname",       limit: 255
    t.string   "title",         limit: 255
    t.string   "forename",      limit: 255
    t.string   "email",         limit: 255
    t.integer  "source_id",     limit: 4
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "current",                   default: false
    t.boolean  "teaches"
    t.boolean  "does_cover"
    t.integer  "datasource_id", limit: 4
    t.boolean  "multicover",                default: false
  end

  add_index "staffs", ["datasource_id"], name: "index_staffs_on_datasource_id", using: :btree
  add_index "staffs", ["source_id"], name: "index_staffs_on_source_id", using: :btree

  create_table "staffs_subjects", id: false, force: :cascade do |t|
    t.integer "staff_id",   limit: 4
    t.integer "subject_id", limit: 4
  end

  add_index "staffs_subjects", ["staff_id"], name: "index_staffs_subjects_on_staff_id", using: :btree
  add_index "staffs_subjects", ["subject_id"], name: "index_staffs_subjects_on_subject_id", using: :btree

  create_table "staffs_teachinggrouppersonae", id: false, force: :cascade do |t|
    t.integer "staff_id",                limit: 4
    t.integer "teachinggrouppersona_id", limit: 4
  end

  add_index "staffs_teachinggrouppersonae", ["staff_id"], name: "index_staffs_teachinggrouppersonae_on_staff_id", using: :btree
  add_index "staffs_teachinggrouppersonae", ["teachinggrouppersona_id"], name: "index_staffs_teachinggrouppersonae_on_teachinggrouppersona_id", using: :btree

  create_table "subjects", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.boolean  "current",                   default: true
    t.integer  "datasource_id", limit: 4
    t.integer  "source_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "taggrouppersonae", force: :cascade do |t|
    t.integer  "source_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "taggrouppersonae", ["source_id"], name: "index_taggrouppersonae_on_source_id", using: :btree

  create_table "teachinggrouppersonae", force: :cascade do |t|
    t.integer  "source_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "subject_id", limit: 4
    t.integer  "yeargroup",  limit: 4
  end

  add_index "teachinggrouppersonae", ["source_id"], name: "index_teachinggrouppersonae_on_source_id", using: :btree
  add_index "teachinggrouppersonae", ["subject_id"], name: "index_teachinggrouppersonae_on_subject_id", using: :btree

  create_table "tutorgrouppersonae", force: :cascade do |t|
    t.string   "house",      limit: 255
    t.integer  "staff_id",   limit: 4
    t.integer  "start_year", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_files", force: :cascade do |t|
    t.integer  "owner_id",           limit: 4
    t.string   "original_file_name", limit: 255
    t.string   "nanoid",             limit: 255
    t.integer  "file_size",          limit: 4,   default: 0
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
  end

  add_index "user_files", ["nanoid"], name: "index_user_files_on_nanoid", unique: true, using: :btree

  create_table "user_form_responses", force: :cascade do |t|
    t.integer  "user_form_id", limit: 4
    t.integer  "parent_id",    limit: 4
    t.string   "parent_type",  limit: 255
    t.integer  "user_id",      limit: 4
    t.text     "form_data",    limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",       limit: 4,     default: 0
  end

  add_index "user_form_responses", ["parent_type", "parent_id"], name: "index_user_form_responses_on_parent_type_and_parent_id", using: :btree

  create_table "user_forms", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.integer  "created_by_user_id", limit: 4
    t.integer  "edited_by_user_id",  limit: 4
    t.text     "definition",         limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_profiles", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.text     "permissions", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "known",                     default: true
  end

  create_table "users", force: :cascade do |t|
    t.string   "provider",                    limit: 255
    t.string   "uid",                         limit: 255
    t.string   "name",                        limit: 255
    t.string   "email",                       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "admin",                                     default: false
    t.boolean  "editor",                                    default: false
    t.string   "colour_involved",             limit: 255,   default: "#234B58"
    t.string   "colour_not_involved",         limit: 255,   default: "#254117"
    t.boolean  "arranges_cover",                            default: false
    t.integer  "preferred_event_category_id", limit: 4
    t.boolean  "secretary",                                 default: false
    t.boolean  "show_owned",                                default: true
    t.boolean  "privileged",                                default: false
    t.integer  "firstday",                    limit: 4,     default: 0
    t.string   "default_event_text",          limit: 255,   default: ""
    t.boolean  "public_groups",                             default: false
    t.boolean  "element_owner",                             default: false
    t.boolean  "email_notification",                        default: true
    t.boolean  "can_has_groups",                            default: false
    t.boolean  "can_find_free",                             default: false
    t.boolean  "can_add_concerns",                          default: false
    t.boolean  "can_su",                                    default: false
    t.boolean  "immediate_notification",                    default: false
    t.boolean  "can_roam",                                  default: false
    t.boolean  "clash_weekly",                              default: false
    t.boolean  "clash_daily",                               default: false
    t.boolean  "clash_immediate",                           default: false
    t.boolean  "edit_all_events",                           default: false
    t.boolean  "subedit_all_events",                        default: false
    t.boolean  "exams",                                     default: false
    t.boolean  "invig_weekly",                              default: true
    t.boolean  "invig_daily",                               default: true
    t.date     "last_invig_run_date"
    t.integer  "day_shape_id",                limit: 4
    t.text     "suppressed_eventcategories",  limit: 65535
    t.text     "extra_eventcategories",       limit: 65535
    t.boolean  "list_teachers",                             default: false
    t.boolean  "warn_no_resources",                         default: true
    t.boolean  "can_relocate_lessons",                      default: false
    t.boolean  "can_has_forms",                             default: false
    t.boolean  "show_pre_requisites",                       default: true
    t.integer  "corresponding_staff_id",      limit: 4
    t.boolean  "can_add_resources",                         default: false
    t.boolean  "can_add_notes",                             default: false
    t.integer  "user_profile_id",             limit: 4
    t.text     "permissions",                 limit: 65535
    t.boolean  "demo_user",                                 default: false
    t.boolean  "can_view_forms",                            default: false
    t.boolean  "can_repeat_events",                         default: false
    t.boolean  "can_view_unconfirmed",                      default: false
    t.integer  "current_concern_set_id",      limit: 4
    t.boolean  "confirmation_messages",                     default: true
    t.boolean  "prompt_for_forms",                          default: true
    t.boolean  "can_edit_memberships",                      default: false
    t.string   "uuid",                        limit: 255
    t.boolean  "can_api",                                   default: false
    t.boolean  "can_has_files",                             default: false
    t.boolean  "loading_notification",                      default: true
    t.boolean  "known",                                     default: false
    t.boolean  "can_view_journals",                         default: false
  end

  add_index "users", ["uuid"], name: "index_users_on_uuid", unique: true, using: :btree

end
