# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110603195710) do

  create_table "aae_emails", :force => true do |t|
    t.string   "from"
    t.string   "to"
    t.string   "destination"
    t.string   "reply_type"
    t.string   "subject"
    t.string   "message_id"
    t.datetime "mail_date"
    t.boolean  "attachments",                                  :default => false
    t.boolean  "bounced",                                      :default => false
    t.boolean  "retryable",                                    :default => false
    t.boolean  "vacation",                                     :default => false
    t.string   "bounce_code"
    t.string   "bounce_diagnostic"
    t.text     "raw",                    :limit => 2147483647
    t.integer  "submitted_question_id"
    t.string   "submitted_question_ids"
    t.integer  "account_id"
    t.string   "action_taken"
    t.string   "action_taken_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "accounts", :force => true do |t|
    t.string   "type",                                   :default => "",    :null => false
    t.string   "login",                    :limit => 80,                    :null => false
    t.string   "password",                 :limit => 40
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email",                    :limit => 96
    t.string   "title"
    t.datetime "email_event_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "contributor_agreement"
    t.datetime "contributor_agreement_at"
    t.integer  "account_status"
    t.datetime "last_login_at"
    t.integer  "position_id",                            :default => 0
    t.integer  "location_id",                            :default => 0
    t.integer  "county_id",                              :default => 0
    t.boolean  "retired",                                :default => false
    t.boolean  "vouched",                                :default => false
    t.integer  "vouched_by",                             :default => 0
    t.datetime "vouched_at"
    t.boolean  "emailconfirmed",                         :default => false
    t.boolean  "is_admin",                               :default => false
    t.string   "phonenumber"
    t.string   "feedkey"
    t.boolean  "announcements",                          :default => true
    t.datetime "retired_at"
    t.text     "additionaldata"
    t.boolean  "aae_responder",                          :default => true
    t.string   "time_zone"
    t.boolean  "is_question_wrangler",                   :default => false
    t.string   "base_login_string"
    t.integer  "login_increment"
    t.datetime "vacated_aae_at"
    t.boolean  "first_aae_away_reminder",                :default => false
    t.boolean  "second_aae_away_reminder",               :default => false
    t.integer  "primary_account_id"
  end

  add_index "accounts", ["email"], :name => "email", :unique => true
  add_index "accounts", ["login"], :name => "login", :unique => true
  add_index "accounts", ["vouched", "retired"], :name => "index_users_on_vouched_and_retired"

  create_table "activities", :force => true do |t|
    t.datetime "created_at"
    t.integer  "user_id",                 :default => 0
    t.integer  "activitytype",            :default => 0
    t.integer  "activitycode",            :default => 0
    t.integer  "community_id",            :default => 0
    t.integer  "activity_application_id", :default => 1
    t.string   "ipaddr"
    t.integer  "created_by",              :default => 0
    t.integer  "colleague_id",            :default => 0
    t.integer  "activity_object_id"
    t.integer  "privacy"
    t.string   "activity_uri"
    t.integer  "responsetime"
    t.text     "additionaldata"
  end

  add_index "activities", ["activity_application_id"], :name => "index_activities_on_activity_application_id"
  add_index "activities", ["activity_object_id"], :name => "index_activities_on_activity_object_id"
  add_index "activities", ["activitycode"], :name => "index_activities_on_activitycode"
  add_index "activities", ["activitytype"], :name => "index_activities_on_activitytype"
  add_index "activities", ["created_at", "user_id", "activitycode", "activity_application_id", "community_id", "privacy"], :name => "recordsignature", :unique => true

  create_table "activity_applications", :force => true do |t|
    t.string   "displayname"
    t.string   "shortname"
    t.text     "description"
    t.integer  "activitysourcetype"
    t.string   "activitysource"
    t.boolean  "isactivesource",     :default => true
    t.string   "trust_root_uri"
    t.string   "link_uri"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "activity_events", :force => true do |t|
    t.integer  "user_id",                               :default => 0, :null => false
    t.integer  "activity_application_id",               :default => 0, :null => false
    t.integer  "event",                                 :default => 0, :null => false
    t.string   "ipaddr",                  :limit => 20
    t.text     "eventdata"
    t.datetime "created_at"
  end

  create_table "activity_objects", :force => true do |t|
    t.integer  "activity_application_id", :default => 1
    t.integer  "entrytype"
    t.integer  "namespace"
    t.integer  "foreignid"
    t.integer  "foreignrevision"
    t.string   "source"
    t.string   "sourcewidget"
    t.string   "displaytitle"
    t.text     "fulltitle"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "additionaldata"
  end

  add_index "activity_objects", ["entrytype", "namespace", "foreignid"], :name => "recordsignature", :unique => true

  create_table "admin_events", :force => true do |t|
    t.integer  "user_id",                  :default => 0, :null => false
    t.integer  "event",                    :default => 0, :null => false
    t.string   "ip",         :limit => 20
    t.text     "data"
    t.datetime "created_at"
  end

  create_table "annotation_events", :force => true do |t|
    t.integer  "user_id"
    t.string   "annotation_id"
    t.string   "action"
    t.string   "ip"
    t.datetime "created_at"
    t.string   "login"
    t.text     "additionaldata"
  end

  create_table "annotations", :force => true do |t|
    t.string   "href"
    t.string   "url"
    t.datetime "added_at"
    t.datetime "created_at"
  end

  add_index "annotations", ["url"], :name => "index_annotations_on_url"

  create_table "api_key_events", :force => true do |t|
    t.integer  "api_key_id"
    t.string   "requestaction"
    t.string   "ipaddr",         :limit => 20
    t.text     "additionaldata"
    t.datetime "created_at"
  end

  add_index "api_key_events", ["api_key_id", "created_at"], :name => "index_api_key_events_on_api_key_id_and_created_at"

  create_table "api_keys", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "keyvalue"
    t.integer  "created_by"
    t.boolean  "enabled"
    t.datetime "created_at"
  end

  add_index "api_keys", ["keyvalue"], :name => "index_api_keys_on_keyvalue", :unique => true
  add_index "api_keys", ["user_id", "name"], :name => "index_api_keys_on_user_id_and_name", :unique => true

  create_table "bucketings", :force => true do |t|
    t.integer  "page_id",           :null => false
    t.integer  "content_bucket_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bucketings", ["page_id", "content_bucket_id"], :name => "bucketingindex", :unique => true

  create_table "cached_tags", :force => true do |t|
    t.integer  "tagcacheable_id"
    t.string   "tagcacheable_type"
    t.integer  "owner_id"
    t.integer  "tagging_kind"
    t.integer  "cache_kind"
    t.text     "fulltextlist"
    t.text     "cachedata"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cached_tags", ["tagcacheable_id", "tagcacheable_type", "owner_id", "tagging_kind"], :name => "signature"

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
    t.boolean  "show_to_public", :default => false
  end

  add_index "categories", ["parent_id"], :name => "parent_id_idx"

  create_table "categories_submitted_questions", :id => false, :force => true do |t|
    t.integer "category_id",           :default => 0, :null => false
    t.integer "submitted_question_id", :default => 0, :null => false
  end

  add_index "categories_submitted_questions", ["category_id"], :name => "category_id_idx"
  add_index "categories_submitted_questions", ["submitted_question_id"], :name => "fk_csq_subquestion"

  create_table "chat_accounts", :force => true do |t|
    t.integer  "user_id",    :default => 0, :null => false
    t.string   "username",                  :null => false
    t.string   "password",                  :null => false
    t.string   "name",                      :null => false
    t.string   "email",                     :null => false
    t.datetime "created_at",                :null => false
    t.datetime "updated_at"
  end

  add_index "chat_accounts", ["username"], :name => "username", :unique => true

  create_table "communities", :force => true do |t|
    t.integer  "entrytype",                             :default => 0,     :null => false
    t.string   "name",                                                     :null => false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by",                            :default => 0
    t.string   "uri"
    t.integer  "memberfilter",                          :default => 1
    t.string   "shortname"
    t.string   "public_name"
    t.text     "public_description"
    t.boolean  "is_launched",                           :default => false
    t.integer  "public_topic_id"
    t.text     "cached_content_tag_data"
    t.boolean  "show_in_public_list",                   :default => false
    t.integer  "location_id",                           :default => 0
    t.string   "public_uri"
    t.string   "referer_domain"
    t.string   "institution_code",        :limit => 10
    t.integer  "logo_id",                               :default => 0
    t.boolean  "connect_to_drupal",                     :default => false
    t.integer  "drupal_node_id"
    t.boolean  "connect_to_google_apps",                :default => false
    t.integer  "widget_id"
    t.boolean  "active",                                :default => true
    t.string   "homage_name"
    t.integer  "homage_id"
  end

  add_index "communities", ["name"], :name => "communities_name_index", :unique => true
  add_index "communities", ["referer_domain"], :name => "index_communities_on_referer_domain"
  add_index "communities", ["shortname"], :name => "index_communities_on_shortname", :unique => true
  add_index "communities", ["widget_id"], :name => "index_communities_on_widget_id"

  create_table "communityconnections", :force => true do |t|
    t.integer  "user_id"
    t.integer  "community_id"
    t.string   "connectiontype"
    t.integer  "connectioncode"
    t.boolean  "sendnotifications"
    t.integer  "connected_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "communityconnections", ["connectiontype"], :name => "index_communityconnections_on_connectiontype"
  add_index "communityconnections", ["user_id", "community_id"], :name => "user_community", :unique => true

  create_table "content_buckets", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at", :null => false
  end

  add_index "content_buckets", ["name"], :name => "index_content_buckets_on_name", :unique => true

  create_table "counties", :force => true do |t|
    t.integer "fipsid",                    :default => 0,  :null => false
    t.integer "location_id",               :default => 0,  :null => false
    t.integer "state_fipsid",              :default => 0,  :null => false
    t.string  "countycode",   :limit => 3, :default => "", :null => false
    t.string  "name",                      :default => "", :null => false
    t.string  "censusclass",  :limit => 2, :default => "", :null => false
  end

  add_index "counties", ["fipsid"], :name => "fipsid", :unique => true
  add_index "counties", ["location_id"], :name => "fk_loc_id"
  add_index "counties", ["name"], :name => "name"
  add_index "counties", ["state_fipsid"], :name => "state_fipsid"

  create_table "daily_numbers", :force => true do |t|
    t.integer  "datasource_id"
    t.string   "datasource_type", :limit => 50
    t.date     "datadate"
    t.string   "datatype",        :limit => 50
    t.integer  "total"
    t.integer  "thatday"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "additionaldata"
  end

  add_index "daily_numbers", ["datasource_id", "datasource_type", "datadate", "datatype"], :name => "dn_index"

  create_table "db_files", :force => true do |t|
    t.binary "data", :limit => 2147483647
  end

  create_table "directory_item_caches", :force => true do |t|
    t.integer  "user_id"
    t.text     "public_attributes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "directory_item_caches", ["user_id"], :name => "index_directory_item_caches_on_user_id"

  create_table "email_aliases", :force => true do |t|
    t.integer  "user_id",          :default => 0,     :null => false
    t.integer  "community_id",     :default => 0,     :null => false
    t.string   "mail_alias",                          :null => false
    t.string   "destination",                         :null => false
    t.integer  "alias_type",       :default => 0,     :null => false
    t.integer  "created_by",       :default => 1
    t.integer  "last_modified_by", :default => 1
    t.boolean  "disabled",         :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "email_aliases", ["destination"], :name => "destination_ndx"
  add_index "email_aliases", ["mail_alias"], :name => "alias_ndx"

  create_table "expertise_areas", :force => true do |t|
    t.integer  "category_id", :null => false
    t.integer  "user_id",     :null => false
    t.datetime "created_at"
  end

  add_index "expertise_areas", ["category_id"], :name => "index_expertise_areas_on_category_id"
  add_index "expertise_areas", ["user_id"], :name => "index_expertise_areas_on_user_id"

  create_table "expertise_counties", :force => true do |t|
    t.integer "fipsid",                             :null => false
    t.integer "expertise_location_id",              :null => false
    t.integer "state_fipsid",                       :null => false
    t.string  "countycode",            :limit => 3, :null => false
    t.string  "name",                               :null => false
    t.string  "censusclass",           :limit => 2, :null => false
  end

  add_index "expertise_counties", ["expertise_location_id"], :name => "index_expertise_counties_on_location_id"
  add_index "expertise_counties", ["name"], :name => "index_expertise_counties_on_name"

  create_table "expertise_counties_users", :id => false, :force => true do |t|
    t.integer "expertise_county_id", :default => 0, :null => false
    t.integer "user_id",             :default => 0, :null => false
  end

  add_index "expertise_counties_users", ["user_id", "expertise_county_id"], :name => "fk_counties_users", :unique => true

  create_table "expertise_events", :force => true do |t|
    t.integer  "expertise_id", :null => false
    t.integer  "user_id",      :null => false
    t.string   "event_type",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "expertise_locations", :force => true do |t|
    t.integer "fipsid",                     :null => false
    t.integer "entrytype",                  :null => false
    t.string  "name",                       :null => false
    t.string  "abbreviation", :limit => 10, :null => false
  end

  add_index "expertise_locations", ["name"], :name => "index_expertise_locations_on_name", :unique => true

  create_table "expertise_locations_users", :id => false, :force => true do |t|
    t.integer "expertise_location_id", :default => 0, :null => false
    t.integer "user_id",               :default => 0, :null => false
  end

  add_index "expertise_locations_users", ["user_id", "expertise_location_id"], :name => "fk_locations_users", :unique => true

  create_table "feed_locations", :force => true do |t|
    t.text     "uri",                                   :null => false
    t.boolean  "active",             :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.boolean  "retrieve_with_time", :default => false
  end

  create_table "file_attachments", :force => true do |t|
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.integer  "submitted_question_id"
    t.integer  "response_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "geo_names", :force => true do |t|
    t.string  "feature_name",       :limit => 121
    t.string  "feature_class",      :limit => 51
    t.string  "state_abbreviation", :limit => 3
    t.string  "state_code",         :limit => 3
    t.string  "county",             :limit => 101
    t.string  "county_code",        :limit => 4
    t.string  "lat_dms",            :limit => 8
    t.string  "long_dms",           :limit => 9
    t.float   "lat"
    t.float   "long"
    t.string  "source_lat_dms",     :limit => 8
    t.string  "source_long_dms",    :limit => 9
    t.float   "source_lat"
    t.float   "source_long"
    t.integer "elevation"
    t.string  "map_name"
    t.string  "create_date_txt"
    t.string  "edit_date_txt"
    t.date    "create_date"
    t.date    "edit_date"
  end

  add_index "geo_names", ["feature_name", "state_abbreviation", "county"], :name => "name_state_county_ndx"

  create_table "google_accounts", :force => true do |t|
    t.integer  "user_id",          :default => 0,     :null => false
    t.string   "username",                            :null => false
    t.boolean  "no_sync_password", :default => false
    t.string   "password",                            :null => false
    t.string   "given_name",                          :null => false
    t.string   "family_name",                         :null => false
    t.boolean  "is_admin",         :default => false
    t.boolean  "suspended",        :default => false
    t.datetime "apps_updated_at"
    t.boolean  "has_error",        :default => false
    t.text     "last_error"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "google_accounts", ["user_id"], :name => "index_google_accounts_on_user_id", :unique => true

  create_table "google_groups", :force => true do |t|
    t.integer  "community_id",     :default => 0,     :null => false
    t.string   "group_id",                            :null => false
    t.string   "group_name",                          :null => false
    t.string   "email_permission",                    :null => false
    t.datetime "apps_updated_at"
    t.boolean  "has_error",        :default => false
    t.text     "last_error"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "google_groups", ["community_id"], :name => "index_google_groups_on_community_id", :unique => true

  create_table "help_feeds", :force => true do |t|
    t.string   "title"
    t.string   "etag"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "invitations", :force => true do |t|
    t.integer  "user_id",                      :default => 0, :null => false
    t.string   "token",          :limit => 40,                :null => false
    t.string   "email",                                       :null => false
    t.datetime "created_at",                                  :null => false
    t.datetime "accepted_at"
    t.integer  "colleague_id",                 :default => 0
    t.datetime "reminder_at"
    t.integer  "reminder_count",               :default => 0
    t.text     "additionaldata"
    t.integer  "resent_count",                 :default => 0
    t.datetime "resent_at"
    t.text     "message"
    t.text     "resendmessage"
    t.integer  "status",                       :default => 0
  end

  add_index "invitations", ["colleague_id"], :name => "index_invitations_on_colleague_id"
  add_index "invitations", ["email"], :name => "email"
  add_index "invitations", ["token"], :name => "tokenlookup"
  add_index "invitations", ["user_id"], :name => "index_invitations_on_user_id"

  create_table "learn_connections", :force => true do |t|
    t.integer  "user_id"
    t.string   "email",            :null => false
    t.integer  "learn_session_id", :null => false
    t.integer  "connectiontype",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "learn_connections", ["learn_session_id", "connectiontype"], :name => "index_learn_connections_on_learn_session_id_and_connectiontype"

  create_table "learn_sessions", :force => true do |t|
    t.text     "title",            :null => false
    t.text     "description",      :null => false
    t.datetime "session_start",    :null => false
    t.datetime "session_end",      :null => false
    t.integer  "session_length",   :null => false
    t.text     "location"
    t.text     "recording"
    t.integer  "created_by",       :null => false
    t.integer  "last_modified_by", :null => false
    t.datetime "updated_at"
    t.datetime "created_at"
    t.string   "time_zone"
  end

  add_index "learn_sessions", ["session_start", "session_end"], :name => "index_learn_sessions_on_session_start_and_session_end"

  create_table "link_stats", :force => true do |t|
    t.integer  "page_id"
    t.integer  "total"
    t.integer  "external"
    t.integer  "internal"
    t.integer  "wanted"
    t.integer  "local"
    t.integer  "broken"
    t.integer  "warning"
    t.integer  "redirected"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "link_stats", ["page_id"], :name => "index_content_link_stats_on_content_id"

  create_table "linkings", :force => true do |t|
    t.integer  "link_id"
    t.integer  "page_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "linkings", ["link_id", "page_id"], :name => "recordsignature", :unique => true

  create_table "links", :force => true do |t|
    t.integer  "linktype"
    t.integer  "page_id"
    t.string   "host"
    t.string   "source_host"
    t.string   "path"
    t.string   "fingerprint"
    t.text     "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status"
    t.integer  "error_count",            :default => 0
    t.datetime "last_check_at"
    t.integer  "last_check_status"
    t.boolean  "last_check_response"
    t.string   "last_check_code"
    t.text     "last_check_information"
  end

  add_index "links", ["fingerprint"], :name => "index_content_links_on_original_fingerprint", :unique => true
  add_index "links", ["page_id", "status", "linktype"], :name => "coreindex"

  create_table "lists", :force => true do |t|
    t.string   "name",                :limit => 50
    t.boolean  "deleted",                           :default => false
    t.boolean  "managed",                           :default => false
    t.boolean  "advertised",                        :default => true
    t.boolean  "private_archive",                   :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "password"
    t.datetime "last_mailman_update"
    t.integer  "community_id"
    t.string   "connectiontype"
  end

  create_table "locations", :force => true do |t|
    t.integer "fipsid",                     :default => 0,  :null => false
    t.integer "entrytype",                  :default => 0,  :null => false
    t.string  "name",                       :default => "", :null => false
    t.string  "abbreviation", :limit => 10, :default => "", :null => false
    t.string  "office_link"
  end

  add_index "locations", ["fipsid"], :name => "fipsid", :unique => true
  add_index "locations", ["name"], :name => "name", :unique => true

  create_table "logos", :force => true do |t|
    t.string   "filename"
    t.string   "content_type"
    t.integer  "size"
    t.integer  "width"
    t.integer  "height"
    t.integer  "parent_id"
    t.string   "thumbnail"
    t.datetime "created_at"
    t.integer  "db_file_id"
    t.integer  "logotype",     :default => 0
  end

  create_table "notifications", :force => true do |t|
    t.integer  "notifytype",     :default => 0
    t.integer  "account_id",     :default => 0,     :null => false
    t.integer  "created_by",     :default => 0
    t.integer  "community_id",   :default => 0,     :null => false
    t.boolean  "sent_email",     :default => false
    t.boolean  "send_error",     :default => false
    t.datetime "sent_email_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "additionaldata"
    t.boolean  "send_on_create", :default => false
  end

  add_index "notifications", ["send_error"], :name => "index_notifications_on_send_error"
  add_index "notifications", ["sent_email"], :name => "index_notifications_on_sent_email"

  create_table "old_institutions", :force => true do |t|
    t.integer  "entrytype",                           :default => 0,     :null => false
    t.string   "location_abbreviation", :limit => 4
    t.string   "name",                                                   :null => false
    t.string   "code",                  :limit => 10
    t.string   "uri"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "normalizedname"
    t.integer  "location_id",                         :default => 0
    t.integer  "created_by",                          :default => 0
    t.string   "creatorlogin"
    t.integer  "institutionalteam_id",                :default => 0
    t.string   "public_uri"
    t.string   "referer_domain"
    t.boolean  "shared_logo",                         :default => false
    t.boolean  "show_in_public_list",                 :default => false
  end

  add_index "old_institutions", ["location_abbreviation"], :name => "STATE_ABBR"
  add_index "old_institutions", ["name"], :name => "NAME", :unique => true
  add_index "old_institutions", ["referer_domain"], :name => "index_institutions_on_referer_domain"

  create_table "open_id_associations", :force => true do |t|
    t.binary  "server_url", :null => false
    t.string  "handle",     :null => false
    t.binary  "secret",     :null => false
    t.integer "issued",     :null => false
    t.integer "lifetime",   :null => false
    t.string  "assoc_type", :null => false
  end

  create_table "open_id_nonces", :force => true do |t|
    t.string  "server_url", :null => false
    t.integer "timestamp",  :null => false
    t.string  "salt",       :null => false
  end

  create_table "opie_approvals", :force => true do |t|
    t.integer  "user_id",    :default => 0, :null => false
    t.string   "trust_root",                :null => false
    t.datetime "created_at",                :null => false
  end

  create_table "page_sources", :force => true do |t|
    t.string   "name"
    t.string   "uri",                                          :null => false
    t.string   "page_uri"
    t.string   "page_uri_column"
    t.string   "demo_uri"
    t.string   "demo_page_uri"
    t.boolean  "active",                     :default => true
    t.boolean  "retrieve_with_time",         :default => true
    t.string   "default_datatype"
    t.text     "default_request_options"
    t.datetime "latest_source_time"
    t.datetime "last_requested_at"
    t.boolean  "last_requested_success"
    t.text     "last_requested_information"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pages", :force => true do |t|
    t.string   "datatype"
    t.integer  "indexed",                                      :default => 1
    t.text     "title"
    t.string   "url_title",              :limit => 101
    t.text     "content",                :limit => 2147483647
    t.integer  "content_length"
    t.integer  "content_words"
    t.text     "original_content",       :limit => 2147483647
    t.datetime "source_created_at"
    t.datetime "source_updated_at"
    t.string   "source"
    t.text     "source_id"
    t.text     "source_url"
    t.string   "source_url_fingerprint"
    t.boolean  "is_dpl",                                       :default => false
    t.text     "reference_pages"
    t.integer  "migrated_id"
    t.boolean  "has_broken_links",                             :default => false
    t.text     "coverage"
    t.text     "state_abbreviations"
    t.datetime "event_start"
    t.string   "time_zone"
    t.text     "event_location"
    t.integer  "event_duration"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "page_source_id"
    t.text     "cached_content_tags"
    t.text     "old_source_url"
    t.boolean  "event_all_day"
  end

  add_index "pages", ["datatype"], :name => "index_pages_on_datatype"
  add_index "pages", ["event_start"], :name => "index_pages_on_event_start"
  add_index "pages", ["migrated_id"], :name => "index_pages_on_migrated_id"
  add_index "pages", ["source_created_at", "source_updated_at"], :name => "index_pages_on_source_created_at_and_source_updated_at"
  add_index "pages", ["source_url_fingerprint"], :name => "index_pages_on_source_url_fingerprint", :unique => true
  add_index "pages", ["title"], :name => "index_pages_on_title", :length => {"title"=>"255"}

  create_table "positions", :force => true do |t|
    t.integer  "entrytype",  :default => 0, :null => false
    t.string   "name",                      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "positions", ["name"], :name => "NAME", :unique => true

  create_table "privacy_settings", :force => true do |t|
    t.integer  "user_id"
    t.string   "item"
    t.boolean  "is_public",  :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "privacy_settings", ["user_id"], :name => "index_privacy_settings_on_user_id"

  create_table "responses", :force => true do |t|
    t.integer  "resolver_id"
    t.integer  "submitter_id"
    t.integer  "submitted_question_id",                       :null => false
    t.text     "response",                                    :null => false
    t.integer  "duration_since_last",                         :null => false
    t.boolean  "sent",                     :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "contributing_question_id"
    t.text     "signature"
    t.string   "user_ip"
    t.string   "user_agent"
    t.string   "referrer"
  end

  add_index "responses", ["resolver_id"], :name => "index_responses_on_user_id"
  add_index "responses", ["submitted_question_id"], :name => "index_responses_on_submitted_question_id"
  add_index "responses", ["submitter_id"], :name => "index_responses_on_submitter_id"

  create_table "roles", :force => true do |t|
    t.string "name"
  end

  create_table "search_questions", :force => true do |t|
    t.integer  "entrytype"
    t.integer  "foreignid"
    t.integer  "foreignrevision",                       :default => 0
    t.string   "source"
    t.string   "sourcewidget"
    t.string   "displaytitle"
    t.text     "fulltitle"
    t.text     "content",         :limit => 2147483647
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "search_questions", ["entrytype", "foreignid"], :name => "recordsignature", :unique => true
  add_index "search_questions", ["fulltitle", "content"], :name => "title_content_full_index"

  create_table "social_networks", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "network",     :limit => 96
    t.string   "displayname"
    t.string   "accountid",   :limit => 96
    t.string   "description"
    t.string   "accounturl"
    t.integer  "privacy"
    t.boolean  "is_public",                 :default => false
  end

  add_index "social_networks", ["network", "accountid"], :name => "index_social_networks_on_network_and_accountid"
  add_index "social_networks", ["privacy"], :name => "index_social_networks_on_privacy"
  add_index "social_networks", ["user_id"], :name => "index_social_networks_on_user_id"

  create_table "sponsors", :force => true do |t|
    t.integer "logo_id"
    t.integer "position"
    t.string  "name"
    t.string  "level"
  end

  create_table "submitted_question_events", :force => true do |t|
    t.integer  "submitted_question_id"
    t.integer  "initiated_by_id"
    t.integer  "recipient_id"
    t.datetime "created_at"
    t.text     "response"
    t.integer  "contributing_question"
    t.string   "category"
    t.integer  "event_state",                                           :null => false
    t.text     "additionaldata"
    t.integer  "response_id"
    t.integer  "submitter_id"
    t.boolean  "sent",                               :default => false, :null => false
    t.integer  "previous_event_id"
    t.integer  "duration_since_last"
    t.integer  "previous_recipient_id"
    t.integer  "previous_initiator_id"
    t.integer  "previous_handling_event_id"
    t.integer  "duration_since_last_handling_event"
    t.integer  "previous_handling_event_state"
    t.integer  "previous_handling_recipient_id"
    t.integer  "previous_handling_initiator_id"
    t.string   "previous_category"
  end

  add_index "submitted_question_events", ["created_at", "event_state", "previous_handling_recipient_id"], :name => "handling_idx"
  add_index "submitted_question_events", ["initiated_by_id"], :name => "initiated_by_idx"
  add_index "submitted_question_events", ["recipient_id"], :name => "subject_user_idx"
  add_index "submitted_question_events", ["submitted_question_id"], :name => "submitted_question_id_idx"
  add_index "submitted_question_events", ["submitter_id"], :name => "index_submitted_question_events_on_submitter_id"

  create_table "submitted_questions", :force => true do |t|
    t.integer  "resolved_by"
    t.integer  "current_contributing_question"
    t.string   "status",                        :default => "",    :null => false
    t.text     "asked_question",                                   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.boolean  "duplicate",                     :default => false, :null => false
    t.string   "external_app_id"
    t.string   "submitter_email"
    t.datetime "resolved_at"
    t.integer  "external_id"
    t.datetime "question_updated_at"
    t.text     "current_response"
    t.string   "resolver_email"
    t.string   "question_fingerprint",                             :null => false
    t.string   "submitter_firstname",           :default => "",    :null => false
    t.string   "submitter_lastname",            :default => "",    :null => false
    t.integer  "county_id"
    t.integer  "location_id"
    t.boolean  "spam",                          :default => false, :null => false
    t.string   "user_ip",                       :default => "",    :null => false
    t.string   "user_agent",                    :default => "",    :null => false
    t.string   "referrer",                      :default => "",    :null => false
    t.string   "widget_name"
    t.integer  "status_state",                                     :null => false
    t.string   "zip_code"
    t.integer  "widget_id"
    t.integer  "submitter_id",                  :default => 0
    t.boolean  "show_publicly",                 :default => true
    t.datetime "last_assigned_at"
    t.datetime "last_opened_at",                                   :null => false
    t.boolean  "is_api"
  end

  add_index "submitted_questions", ["county_id"], :name => "fk_sq_county"
  add_index "submitted_questions", ["created_at"], :name => "created_at_idx"
  add_index "submitted_questions", ["current_contributing_question"], :name => "fk_qu_sq"
  add_index "submitted_questions", ["location_id"], :name => "fk_sq_location"
  add_index "submitted_questions", ["question_fingerprint"], :name => "index_submitted_questions_on_question_fingerprint"
  add_index "submitted_questions", ["resolved_at"], :name => "resolved_at_idx"
  add_index "submitted_questions", ["resolved_by"], :name => "resolved_by_idx"
  add_index "submitted_questions", ["status_state"], :name => "index_submitted_questions_on_status_state"
  add_index "submitted_questions", ["submitter_id"], :name => "index_submitted_questions_on_submitter_id"
  add_index "submitted_questions", ["user_id"], :name => "fk_usr_sq"
  add_index "submitted_questions", ["user_id"], :name => "user_id_idx"
  add_index "submitted_questions", ["widget_name"], :name => "index_submitted_questions_on_widget_name"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id",                                         :null => false
    t.integer  "taggable_id",                                    :null => false
    t.string   "taggable_type",     :limit => 32
    t.string   "tag_display",                                    :null => false
    t.integer  "owner_id",                                       :null => false
    t.integer  "weight",                          :default => 1, :null => false
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at"
    t.integer  "tagging_kind"
    t.string   "old_taggable_type"
    t.integer  "old_taggable_id"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "tagging_kind", "owner_id"], :name => "taggingindex", :unique => true
  add_index "taggings", ["taggable_id", "taggable_type", "tagging_kind"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_tagging_kind"

  create_table "tags", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at", :null => false
  end

  add_index "tags", ["name"], :name => "index_tags_on_name", :unique => true

  create_table "topics", :force => true do |t|
    t.string "name"
  end

  create_table "update_times", :force => true do |t|
    t.integer  "datasource_id"
    t.string   "datasource_type",     :limit => 25
    t.string   "datatype",            :limit => 25
    t.datetime "last_datasourced_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "additionaldata"
  end

  add_index "update_times", ["datasource_type", "datasource_id", "datatype"], :name => "recordsignature", :unique => true

  create_table "user_emails", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "entrytype"
    t.string   "email",      :limit => 96
    t.integer  "privacy"
  end

  add_index "user_emails", ["email"], :name => "email", :unique => true
  add_index "user_emails", ["privacy"], :name => "index_user_emails_on_privacy"
  add_index "user_emails", ["user_id"], :name => "index_user_emails_on_user_id"

  create_table "user_events", :force => true do |t|
    t.string   "login",                                       :null => false
    t.string   "description"
    t.string   "ip",             :limit => 20
    t.datetime "created_at"
    t.string   "appname"
    t.integer  "user_id",                      :default => 0
    t.integer  "etype",                        :default => 0
    t.text     "additionaldata"
  end

  create_table "user_preferences", :force => true do |t|
    t.integer  "user_id",    :default => 0,  :null => false
    t.string   "name",       :default => "", :null => false
    t.text     "setting",                    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_preferences", ["user_id"], :name => "fk_preferences_user"

  create_table "user_roles", :force => true do |t|
    t.integer  "role_id"
    t.integer  "user_id"
    t.integer  "category_id"
    t.datetime "created_at"
    t.integer  "widget_id"
  end

  create_table "user_tokens", :force => true do |t|
    t.integer  "user_id",                      :default => 0, :null => false
    t.integer  "tokentype",                    :default => 0, :null => false
    t.string   "token",          :limit => 40,                :null => false
    t.text     "tokendata"
    t.datetime "created_at",                                  :null => false
    t.datetime "expires_at",                                  :null => false
    t.datetime "extended_at"
    t.integer  "extended_count",               :default => 0
  end

  add_index "user_tokens", ["token"], :name => "tokenlookup"

  create_table "widget_events", :force => true do |t|
    t.integer  "widget_id",  :null => false
    t.integer  "user_id",    :null => false
    t.string   "event",      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "widgets", :force => true do |t|
    t.string   "name",                              :null => false
    t.string   "fingerprint",                       :null => false
    t.string   "old_widget_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",         :default => true,  :null => false
    t.integer  "user_id",                           :null => false
    t.string   "email_from"
    t.boolean  "upload_capable", :default => false
    t.boolean  "show_location"
    t.boolean  "enable_tags"
    t.integer  "location_id"
    t.integer  "county_id"
    t.boolean  "group_notify",   :default => false
  end

  add_index "widgets", ["fingerprint"], :name => "index_widgets_on_fingerprint", :unique => true

  create_table "zip_codes", :force => true do |t|
    t.integer "zip_code"
    t.string  "city"
    t.string  "state"
    t.string  "county"
    t.integer "area_code"
    t.string  "city_type"
    t.string  "city_alias_abbreviation"
    t.string  "city_alias_name"
    t.float   "latitude"
    t.float   "longitude"
    t.integer "time_zone"
    t.integer "elevation"
    t.integer "county_fips"
    t.string  "day_light_savings"
  end

  add_index "zip_codes", ["state"], :name => "fk_statezip"
  add_index "zip_codes", ["zip_code"], :name => "zipcode"

end
