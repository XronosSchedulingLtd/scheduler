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

ActiveRecord::Schema.define(version: 2021_01_06_163634) do

  create_table "ad_hoc_domain_controllers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "ad_hoc_domain_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ad_hoc_domain_id"], name: "index_ad_hoc_domain_controllers_on_ad_hoc_domain_id"
    t.index ["user_id"], name: "index_ad_hoc_domain_controllers_on_user_id"
  end

  create_table "ad_hoc_domain_pupil_courses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "pupil_id"
    t.integer "ad_hoc_domain_staff_id"
    t.integer "minutes", default: 30
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ad_hoc_domain_staff_id"], name: "index_ad_hoc_domain_pupil_courses_on_ad_hoc_domain_staff_id"
    t.index ["pupil_id"], name: "index_ad_hoc_domain_pupil_courses_on_pupil_id"
  end

  create_table "ad_hoc_domain_staffs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "staff_id"
    t.integer "ad_hoc_domain_subject_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ad_hoc_domain_subject_id"], name: "index_ad_hoc_domain_staffs_on_ad_hoc_domain_subject_id"
    t.index ["staff_id"], name: "index_ad_hoc_domain_staffs_on_staff_id"
  end

  create_table "ad_hoc_domain_subjects", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "ad_hoc_domain_id"
    t.integer "subject_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ad_hoc_domain_id"], name: "index_ad_hoc_domain_subjects_on_ad_hoc_domain_id"
    t.index ["subject_id"], name: "index_ad_hoc_domain_subjects_on_subject_id"
  end

  create_table "ad_hoc_domains", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.integer "eventsource_id"
    t.integer "eventcategory_id"
    t.integer "connected_property_id"
    t.integer "default_day_shape_id"
    t.integer "datasource_id"
    t.integer "default_lesson_mins", default: 30
    t.integer "mins_step", default: 15
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ahoy_messages", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "user_id"
    t.string "user_type"
    t.text "to"
    t.string "mailer"
    t.text "subject"
    t.text "content", limit: 16777215
    t.datetime "sent_at"
    t.index ["user_type", "user_id"], name: "index_ahoy_messages_on_user_type_and_user_id"
  end

  create_table "attachments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "parent_id"
    t.string "parent_type"
    t.integer "user_file_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id", "parent_type"], name: "index_attachments_on_parent_id_and_parent_type"
    t.index ["user_file_id"], name: "index_attachments_on_user_file_id"
  end

  create_table "comments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "parent_id"
    t.string "parent_type"
    t.integer "user_id"
    t.text "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["parent_type", "parent_id"], name: "index_comments_on_parent_type_and_parent_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "commitments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "event_id"
    t.integer "element_id"
    t.integer "covering_id"
    t.boolean "names_event", default: false
    t.integer "source_id"
    t.boolean "tentative", default: false
    t.string "reason", default: ""
    t.integer "by_whom_id"
    t.integer "proto_commitment_id"
    t.integer "request_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "status", default: 0
    t.index ["by_whom_id"], name: "index_commitments_on_by_whom_id"
    t.index ["covering_id"], name: "index_commitments_on_covering_id"
    t.index ["element_id"], name: "index_commitments_on_element_id"
    t.index ["event_id"], name: "index_commitments_on_event_id"
    t.index ["proto_commitment_id"], name: "index_commitments_on_proto_commitment_id"
    t.index ["request_id"], name: "index_commitments_on_request_id"
    t.index ["status"], name: "index_commitments_on_status"
    t.index ["tentative"], name: "index_commitments_on_tentative"
  end

  create_table "concern_sets", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.integer "owner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "concerns", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "user_id"
    t.integer "element_id"
    t.boolean "equality", default: false, null: false
    t.boolean "owns", default: false, null: false
    t.boolean "visible", default: true, null: false
    t.string "colour", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "auto_add", default: false
    t.boolean "edit_any", default: false
    t.boolean "skip_permissions", default: false
    t.boolean "seek_permission", default: false
    t.boolean "list_teachers", default: false
    t.boolean "subedit_any", default: false
    t.integer "concern_set_id"
    t.boolean "assistant_to", default: false
    t.index ["element_id"], name: "index_concerns_on_element_id"
    t.index ["user_id"], name: "index_concerns_on_user_id"
  end

  create_table "datasources", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "elements", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.integer "entity_id"
    t.string "entity_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "current", default: false
    t.integer "owner_id"
    t.string "preferred_colour"
    t.boolean "owned", default: false
    t.string "uuid"
    t.integer "user_form_id"
    t.boolean "add_directly", default: true
    t.boolean "viewable", default: true
    t.index ["entity_id"], name: "index_elements_on_entity_id"
    t.index ["entity_type", "entity_id"], name: "index_elements_on_entity_type_and_entity_id"
    t.index ["owner_id"], name: "index_elements_on_owner_id"
    t.index ["uuid"], name: "index_elements_on_uuid", unique: true
  end

  create_table "eras", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.date "starts_on"
    t.date "ends_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "source_id"
    t.string "short_name", default: ""
  end

  create_table "event_collections", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "era_id"
    t.date "repetition_start_date"
    t.date "repetition_end_date"
    t.string "days_of_week"
    t.string "weeks"
    t.integer "when_in_month", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "update_requested_at"
    t.datetime "update_started_at"
    t.datetime "update_finished_at"
    t.integer "lock_version", default: 0, null: false
    t.integer "requesting_user_id"
    t.boolean "preserve_earlier", default: false
    t.boolean "preserve_later", default: false
    t.boolean "preserve_historical", default: true
    t.index ["requesting_user_id"], name: "index_event_collections_on_requesting_user_id"
  end

  create_table "eventcategories", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.integer "pecking_order", default: 20
    t.boolean "schoolwide"
    t.boolean "publish"
    t.boolean "public"
    t.boolean "for_users"
    t.boolean "unimportant"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "can_merge", default: false
    t.boolean "can_borrow", default: false
    t.boolean "compactable", default: true
    t.boolean "deprecated", default: false
    t.boolean "privileged", default: false
    t.boolean "visible", default: true
    t.boolean "clashcheck", default: false
    t.boolean "busy", default: true
    t.boolean "timetable", default: false
    t.boolean "confidential", default: false
  end

  create_table "events", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.text "body"
    t.integer "eventcategory_id", null: false
    t.integer "eventsource_id", null: false
    t.integer "owner_id"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.boolean "approximate", default: false
    t.boolean "non_existent", default: false
    t.boolean "private", default: false
    t.integer "reference_id"
    t.string "reference_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "all_day", default: false
    t.boolean "compound", default: false
    t.integer "source_id", default: 0
    t.string "source_hash"
    t.integer "organiser_id"
    t.text "organiser_ref"
    t.boolean "complete", default: true
    t.boolean "constrained", default: false
    t.boolean "has_clashes", default: false
    t.integer "proto_event_id"
    t.string "flagcolour"
    t.integer "event_collection_id"
    t.boolean "confidential", default: false
    t.boolean "locked", default: false
    t.index ["complete"], name: "index_events_on_complete"
    t.index ["ends_at"], name: "index_events_on_ends_at"
    t.index ["event_collection_id"], name: "index_events_on_event_collection_id"
    t.index ["eventcategory_id"], name: "index_events_on_eventcategory_id"
    t.index ["eventsource_id"], name: "index_events_on_eventsource_id"
    t.index ["has_clashes"], name: "index_events_on_has_clashes"
    t.index ["non_existent"], name: "index_events_on_non_existent"
    t.index ["organiser_id"], name: "index_events_on_organiser_id"
    t.index ["owner_id"], name: "index_events_on_owner_id"
    t.index ["proto_event_id"], name: "index_events_on_proto_event_id"
    t.index ["source_hash"], name: "index_events_on_source_hash"
    t.index ["source_id"], name: "index_events_on_source_id"
    t.index ["starts_at"], name: "index_events_on_starts_at"
  end

  create_table "eventsources", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "exam_cycles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.integer "default_rota_template_id"
    t.date "starts_on"
    t.date "ends_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "default_group_element_id"
    t.integer "default_quantity", default: 5
    t.integer "selector_element_id"
  end

  create_table "freefinders", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "element_id"
    t.string "name"
    t.integer "owner_id"
    t.date "on"
    t.time "start_time"
    t.time "end_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date "ft_start_date"
    t.integer "ft_num_days"
    t.text "ft_days"
    t.time "ft_day_starts_at"
    t.time "ft_day_ends_at"
    t.integer "ft_duration"
    t.text "ft_element_ids"
    t.index ["owner_id"], name: "index_freefinders_on_owner_id"
  end

  create_table "groups", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.date "starts_on", null: false
    t.date "ends_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "persona_id"
    t.string "persona_type"
    t.string "name"
    t.integer "era_id"
    t.boolean "current", default: false
    t.integer "owner_id"
    t.boolean "make_public", default: false
    t.integer "source_id"
    t.string "source_id_str"
    t.integer "datasource_id"
    t.index ["datasource_id"], name: "index_groups_on_datasource_id"
    t.index ["era_id"], name: "index_groups_on_era_id"
    t.index ["owner_id"], name: "index_groups_on_owner_id"
    t.index ["persona_type", "persona_id"], name: "index_groups_on_persona_type_and_persona_id"
    t.index ["source_id"], name: "index_groups_on_source_id"
    t.index ["source_id_str"], name: "index_groups_on_source_id_str"
  end

  create_table "itemreports", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "concern_id"
    t.boolean "compact", default: false
    t.boolean "duration", default: false
    t.boolean "mark_end", default: false
    t.boolean "locations", default: false
    t.boolean "staff", default: false
    t.boolean "pupils", default: false
    t.boolean "periods", default: false
    t.date "starts_on"
    t.date "ends_on"
    t.boolean "twelve_hour", default: false
    t.boolean "end_time", default: true
    t.boolean "breaks", default: false
    t.boolean "suppress_empties", default: false
    t.boolean "tentative", default: false
    t.boolean "firm", default: false
    t.string "categories", default: ""
    t.integer "excluded_element_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "notes", default: false
    t.string "note_flags", default: ""
    t.boolean "no_space", default: false
    t.boolean "enddot", default: true
    t.index ["concern_id"], name: "index_itemreports_on_concern_id"
  end

  create_table "journal_entries", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "journal_id"
    t.integer "user_id"
    t.integer "entry_type"
    t.text "details"
    t.integer "element_id"
    t.datetime "event_starts_at"
    t.datetime "event_ends_at"
    t.boolean "event_all_day"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "repeating", default: false
    t.index ["element_id"], name: "index_journal_entries_on_element_id"
    t.index ["journal_id"], name: "index_journal_entries_on_journal_id"
    t.index ["user_id"], name: "index_journal_entries_on_user_id"
  end

  create_table "journals", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "event_id"
    t.text "event_body"
    t.integer "event_eventcategory_id"
    t.integer "event_owner_id"
    t.datetime "event_starts_at"
    t.datetime "event_ends_at"
    t.boolean "event_all_day"
    t.integer "event_organiser_id"
    t.text "event_organiser_ref"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["event_id"], name: "index_journals_on_event_id"
  end

  create_table "locationaliases", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.integer "source_id"
    t.integer "location_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "display", default: false
    t.boolean "friendly", default: false
    t.integer "datasource_id"
    t.index ["location_id"], name: "index_locationaliases_on_location_id"
  end

  create_table "locations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.boolean "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "current", default: false
    t.integer "num_invigilators", default: 1
    t.integer "weighting", default: 100
    t.integer "subsidiary_to_id"
  end

  create_table "memberships", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "group_id", null: false
    t.integer "element_id", null: false
    t.date "starts_on", null: false
    t.date "ends_on"
    t.boolean "inverse", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["element_id"], name: "index_memberships_on_element_id"
    t.index ["group_id"], name: "index_memberships_on_group_id"
  end

  create_table "notes", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "title", default: ""
    t.text "contents"
    t.integer "parent_id"
    t.string "parent_type"
    t.integer "owner_id"
    t.integer "promptnote_id"
    t.boolean "visible_guest", default: false
    t.boolean "visible_staff", default: true
    t.boolean "visible_pupil", default: false
    t.integer "note_type", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "formatted_contents"
    t.index ["owner_id"], name: "index_notes_on_owner_id"
    t.index ["parent_id"], name: "index_notes_on_parent_id"
    t.index ["parent_type", "parent_id"], name: "index_notes_on_parent_type_and_parent_id"
  end

  create_table "otherhalfgrouppersonae", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["source_id"], name: "index_otherhalfgrouppersonae_on_source_id"
  end

  create_table "pre_requisites", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "label"
    t.text "description"
    t.integer "element_id"
    t.integer "priority"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "pre_creation", default: true
    t.boolean "quick_button", default: true
  end

  create_table "promptnotes", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "title", default: ""
    t.text "prompt"
    t.text "default_contents"
    t.integer "element_id"
    t.boolean "read_only", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["element_id"], name: "index_promptnotes_on_element_id"
  end

  create_table "properties", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "make_public", default: false
    t.boolean "auto_staff", default: false
    t.boolean "auto_pupils", default: false
    t.boolean "current", default: true
    t.boolean "feed_as_category", default: false
    t.boolean "locking", default: false
  end

  create_table "proto_commitments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "proto_event_id"
    t.integer "element_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["element_id"], name: "index_proto_commitments_on_element_id"
    t.index ["proto_event_id"], name: "index_proto_commitments_on_proto_event_id"
  end

  create_table "proto_events", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.text "body"
    t.date "starts_on"
    t.date "ends_on"
    t.integer "eventcategory_id"
    t.integer "eventsource_id"
    t.integer "rota_template_id"
    t.integer "generator_id"
    t.string "generator_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["eventcategory_id"], name: "index_proto_events_on_eventcategory_id"
    t.index ["eventsource_id"], name: "index_proto_events_on_eventsource_id"
    t.index ["generator_id", "generator_type"], name: "index_proto_events_on_generator_id_and_generator_type"
    t.index ["rota_template_id"], name: "index_proto_events_on_rota_template_id"
  end

  create_table "proto_requests", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "proto_event_id"
    t.integer "element_id"
    t.integer "quantity"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["element_id"], name: "index_proto_requests_on_element_id"
    t.index ["proto_event_id"], name: "index_proto_requests_on_proto_event_id"
  end

  create_table "pupils", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.string "surname"
    t.string "forename"
    t.string "known_as"
    t.string "email"
    t.string "candidate_no"
    t.integer "start_year"
    t.integer "source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "current", default: false
    t.integer "datasource_id"
    t.string "house_name", default: ""
    t.index ["datasource_id"], name: "index_pupils_on_datasource_id"
    t.index ["source_id"], name: "index_pupils_on_source_id"
  end

  create_table "requests", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "event_id"
    t.integer "element_id"
    t.integer "proto_request_id"
    t.integer "quantity", default: 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "tentative", default: true
    t.boolean "constraining", default: false
    t.boolean "reconfirmed", default: false
    t.integer "commitments_count", default: 0, null: false
    t.index ["element_id"], name: "index_requests_on_element_id"
    t.index ["event_id"], name: "index_requests_on_event_id"
    t.index ["proto_request_id"], name: "index_requests_on_proto_request_id"
  end

  create_table "resourcegrouppersonae", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "loading_report_days", default: 0
    t.integer "wrapping_mins", default: 0
    t.integer "confirmation_days", default: 0
    t.integer "form_warning_days", default: 0
    t.boolean "needs_people", default: false
  end

  create_table "rota_slots", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "rota_template_id"
    t.time "starts_at"
    t.time "ends_at"
    t.text "days"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["rota_template_id"], name: "index_rota_slots_on_rota_template_id"
  end

  create_table "rota_template_types", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rota_templates", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "rota_template_type_id"
    t.integer "owner_id"
    t.string "owner_type"
  end

  create_table "services", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "current", default: true
    t.boolean "add_directly", default: true
  end

  create_table "settings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "current_era_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "next_era_id"
    t.integer "previous_era_id"
    t.integer "perpetual_era_id"
    t.boolean "enforce_permissions", default: false
    t.string "current_mis"
    t.string "previous_mis"
    t.integer "auth_type", default: 0
    t.string "dns_domain_name", default: ""
    t.string "from_email_address", default: ""
    t.boolean "prefer_https", default: true
    t.boolean "require_uuid", default: false
    t.integer "room_cover_group_element_id"
    t.text "event_creation_markup"
    t.text "event_creation_html"
    t.integer "wrapping_before_mins", default: 60
    t.integer "wrapping_after_mins", default: 30
    t.integer "wrapping_eventcategory_id"
    t.integer "default_display_day_shape_id"
    t.integer "default_free_finder_day_shape_id"
    t.string "title_text"
    t.string "public_title_text"
    t.boolean "tutorgroups_by_house", default: true
    t.string "tutorgroups_name", default: "Tutor group"
    t.string "tutor_name", default: "Tutor"
    t.string "prep_suffix", default: "(P)"
    t.integer "prep_property_element_id"
    t.boolean "ordinalize_years", default: true
    t.integer "max_quick_buttons", default: 0
    t.integer "first_tt_day", default: 1
    t.integer "last_tt_day", default: 5
    t.integer "tt_cycle_weeks", default: 2
    t.string "tt_prep_letter", limit: 2, default: "P"
    t.date "tt_store_start", default: "2006-01-01"
    t.string "busy_string", default: "Busy"
    t.string "user_files_dir", default: "UserFiles"
    t.integer "user_file_allowance", default: 0
    t.integer "email_keep_days", default: 0
    t.integer "event_keep_years", default: 0
    t.string "zoom_link_text"
    t.string "zoom_link_base_url"
    t.integer "datepicker_type", default: 0
    t.integer "ft_default_num_days", default: 7
    t.string "ft_default_days", default: "---\n- 1\n- 2\n- 3\n- 4\n- 5\n"
    t.time "ft_default_day_starts_at", default: "2000-01-01 08:30:00"
    t.time "ft_default_day_ends_at", default: "2000-01-01 17:30:00"
    t.integer "ft_default_duration", default: 60
  end

  create_table "staffs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.string "initials"
    t.string "surname"
    t.string "title"
    t.string "forename"
    t.string "email"
    t.integer "source_id"
    t.boolean "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "current", default: false
    t.boolean "teaches"
    t.boolean "does_cover"
    t.integer "datasource_id"
    t.boolean "multicover", default: false
    t.string "zoom_id"
    t.index ["datasource_id"], name: "index_staffs_on_datasource_id"
    t.index ["source_id"], name: "index_staffs_on_source_id"
  end

  create_table "staffs_subjects", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "staff_id"
    t.integer "subject_id"
    t.index ["staff_id"], name: "index_staffs_subjects_on_staff_id"
    t.index ["subject_id"], name: "index_staffs_subjects_on_subject_id"
  end

  create_table "staffs_teachinggrouppersonae", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "staff_id"
    t.integer "teachinggrouppersona_id"
    t.index ["staff_id"], name: "index_staffs_teachinggrouppersonae_on_staff_id"
    t.index ["teachinggrouppersona_id"], name: "index_staffs_teachinggrouppersonae_on_teachinggrouppersona_id"
  end

  create_table "subjects", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.boolean "current", default: true
    t.integer "datasource_id"
    t.integer "source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "taggrouppersonae", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["source_id"], name: "index_taggrouppersonae_on_source_id"
  end

  create_table "teachinggrouppersonae", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "subject_id"
    t.integer "yeargroup"
    t.index ["source_id"], name: "index_teachinggrouppersonae_on_source_id"
    t.index ["subject_id"], name: "index_teachinggrouppersonae_on_subject_id"
  end

  create_table "tutorgrouppersonae", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "house"
    t.integer "staff_id"
    t.integer "start_year"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_files", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "owner_id"
    t.string "original_file_name"
    t.string "nanoid"
    t.integer "file_size", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "system_created", default: false
    t.index ["nanoid"], name: "index_user_files_on_nanoid", unique: true
  end

  create_table "user_form_responses", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.integer "user_form_id"
    t.integer "parent_id"
    t.string "parent_type"
    t.integer "user_id"
    t.text "form_data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "status", default: 0
    t.index ["parent_type", "parent_id"], name: "index_user_form_responses_on_parent_type_and_parent_id"
  end

  create_table "user_forms", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.integer "created_by_user_id"
    t.integer "edited_by_user_id"
    t.text "definition"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_profiles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name"
    t.text "permissions"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "known", default: true
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.string "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "admin", default: false
    t.boolean "editor", default: false
    t.string "colour_involved", default: "#234B58"
    t.string "colour_not_involved", default: "#254117"
    t.boolean "arranges_cover", default: false
    t.integer "preferred_event_category_id"
    t.boolean "secretary", default: false
    t.boolean "show_owned", default: true
    t.boolean "privileged", default: false
    t.integer "firstday", default: 0
    t.string "default_event_text", default: ""
    t.boolean "public_groups", default: false
    t.boolean "element_owner", default: false
    t.boolean "email_notification", default: true
    t.boolean "can_has_groups", default: false
    t.boolean "can_find_free", default: false
    t.boolean "can_add_concerns", default: false
    t.boolean "can_su", default: false
    t.boolean "immediate_notification", default: false
    t.boolean "can_roam", default: false
    t.boolean "clash_weekly", default: false
    t.boolean "clash_daily", default: false
    t.boolean "clash_immediate", default: false
    t.boolean "edit_all_events", default: false
    t.boolean "subedit_all_events", default: false
    t.boolean "exams", default: false
    t.boolean "invig_weekly", default: true
    t.boolean "invig_daily", default: true
    t.date "last_invig_run_date"
    t.integer "day_shape_id"
    t.text "suppressed_eventcategories"
    t.text "extra_eventcategories"
    t.boolean "list_teachers", default: false
    t.boolean "warn_no_resources", default: true
    t.boolean "can_relocate_lessons", default: false
    t.boolean "can_has_forms", default: false
    t.boolean "show_pre_requisites", default: true
    t.integer "corresponding_staff_id"
    t.boolean "can_add_resources", default: false
    t.boolean "can_add_notes", default: false
    t.integer "user_profile_id"
    t.text "permissions"
    t.boolean "demo_user", default: false
    t.boolean "can_view_forms", default: false
    t.boolean "can_repeat_events", default: false
    t.boolean "can_view_unconfirmed", default: false
    t.integer "current_concern_set_id"
    t.boolean "confirmation_messages", default: true
    t.boolean "prompt_for_forms", default: true
    t.boolean "can_edit_memberships", default: false
    t.string "uuid"
    t.boolean "can_api", default: false
    t.boolean "can_has_files", default: false
    t.boolean "loading_notification", default: true
    t.boolean "known", default: false
    t.boolean "can_view_journals", default: false
    t.boolean "can_make_shadows", default: false
    t.index ["uuid"], name: "index_users_on_uuid", unique: true
  end

end
