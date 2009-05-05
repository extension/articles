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

ActiveRecord::Schema.define(:version => 20090505121757) do

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

  create_table "activity_objects", :force => true do |t|
    t.integer  "activity_application_id", :default => 1
    t.integer  "entrytype"
    t.integer  "namespace"
    t.integer  "foreignid"
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

  create_table "advertisements", :force => true do |t|
    t.integer "tag_id"
    t.integer "image_id"
    t.integer "position"
  end

  create_table "articles", :force => true do |t|
    t.text     "title"
    t.string   "url"
    t.text     "author"
    t.text     "content",          :limit => 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "wiki_created_at"
    t.datetime "wiki_updated_at"
    t.text     "cached_tag_list"
    t.integer  "average_ranking",  :limit => 10,       :precision => 10, :scale => 0
    t.string   "type"
    t.string   "original_url"
    t.text     "original_content", :limit => 16777215
  end

  add_index "articles", ["original_url"], :name => "index_wiki_articles_on_original_url", :unique => true
  add_index "articles", ["title"], :name => "index_wiki_articles_on_title"
  add_index "articles", ["type"], :name => "index_wiki_articles_on_type"
  add_index "articles", ["url"], :name => "index_wiki_articles_on_url", :unique => true

  create_table "assets", :force => true do |t|
    t.string   "filename"
    t.string   "type"
    t.string   "content_type"
    t.integer  "size"
    t.integer  "width"
    t.integer  "height"
    t.integer  "parent_id"
    t.string   "thumbnail"
    t.datetime "created_at"
    t.integer  "db_file_id"
  end

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.string   "default_keyword"
    t.integer  "community_id",    :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
  end

  add_index "categories", ["community_id"], :name => "community_id_idx"
  add_index "categories", ["parent_id"], :name => "parent_id_idx"

  create_table "categories_submitted_questions", :id => false, :force => true do |t|
    t.integer "category_id",           :default => 0, :null => false
    t.integer "submitted_question_id", :default => 0, :null => false
  end

  add_index "categories_submitted_questions", ["category_id"], :name => "category_id_idx"
  add_index "categories_submitted_questions", ["submitted_question_id"], :name => "fk_csq_subquestion"

  create_table "chat_accounts", :force => true do |t|
    t.integer  "user_id",    :default => 0,  :null => false
    t.string   "username",   :default => "", :null => false
    t.string   "password",   :default => "", :null => false
    t.string   "name",       :default => "", :null => false
    t.string   "email",      :default => "", :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at"
  end

  add_index "chat_accounts", ["username"], :name => "username", :unique => true

  create_table "communities", :force => true do |t|
    t.integer  "entrytype",     :default => 0,     :null => false
    t.string   "name",          :default => "",    :null => false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "open",          :default => false
    t.integer  "created_by",    :default => 0
    t.text     "taglist_cache"
    t.string   "uri"
    t.integer  "memberfilter",  :default => 1
    t.boolean  "ismeta",        :default => false
    t.boolean  "listeligible",  :default => true
    t.string   "shortname"
  end

  add_index "communities", ["name"], :name => "communities_name_index", :unique => true

  create_table "communityconnections", :force => true do |t|
    t.integer  "user_id"
    t.integer  "community_id"
    t.string   "connectiontype"
    t.integer  "connectioncode"
    t.boolean  "sendnotifications"
    t.integer  "connected_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "refcount",          :default => 1
  end

  add_index "communityconnections", ["connectiontype"], :name => "index_communityconnections_on_connectiontype"
  add_index "communityconnections", ["user_id", "community_id"], :name => "user_community", :unique => true

  create_table "communitylistconnections", :force => true do |t|
    t.integer  "list_id"
    t.integer  "community_id"
    t.string   "connectiontype"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "communitylistconnections", ["connectiontype"], :name => "index_communitylistconnections_on_connectiontype"
  add_index "communitylistconnections", ["list_id", "community_id"], :name => "list_community", :unique => true

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

  create_table "counties_users", :id => false, :force => true do |t|
    t.integer "county_id", :default => 0, :null => false
    t.integer "user_id",   :default => 0, :null => false
  end

  add_index "counties_users", ["user_id", "county_id"], :name => "fk_counties_users", :unique => true

  create_table "county_links", :force => true do |t|
    t.string  "state",       :default => "", :null => false
    t.string  "office_link", :default => "", :null => false
    t.integer "location_id", :default => 0
  end

  create_table "db_files", :force => true do |t|
    t.binary "data", :limit => 2147483647
  end

  create_table "events", :force => true do |t|
    t.text     "title"
    t.text     "description"
    t.date     "date"
    t.time     "time"
    t.text     "location"
    t.text     "coverage"
    t.text     "state_abbreviations"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.datetime "xcal_updated_at"
    t.datetime "start"
    t.integer  "duration"
    t.boolean  "deleted"
    t.text     "cached_tag_list"
  end

  create_table "expert_questions", :force => true do |t|
    t.integer  "submitted_by"
    t.string   "submitter_email",      :default => "",              :null => false
    t.string   "app_string",           :default => "extension.org", :null => false
    t.datetime "resolved_at"
    t.string   "status",               :default => "",              :null => false
    t.text     "asked_question",                                    :null => false
    t.text     "answer"
    t.boolean  "has_read",             :default => false,           :null => false
    t.text     "reject_message"
    t.datetime "created_at",                                        :null => false
    t.datetime "updated_at"
    t.boolean  "duplicate",            :default => false,           :null => false
    t.integer  "faq_id"
    t.string   "resolver_email"
    t.text     "question_fingerprint",                              :null => false
    t.string   "submitter_firstname",  :default => "",              :null => false
    t.string   "submitter_lastname",   :default => "",              :null => false
    t.integer  "location_id"
    t.integer  "county_id"
    t.string   "category_name"
    t.string   "subcategory_name"
    t.string   "zip_code"
    t.boolean  "spam"
  end

  add_index "expert_questions", ["county_id"], :name => "fk_eq_county"
  add_index "expert_questions", ["faq_id"], :name => "fk_faq_eq"
  add_index "expert_questions", ["location_id"], :name => "fk_eq_location"

  create_table "expertise_areas", :force => true do |t|
    t.integer  "category_id", :null => false
    t.integer  "user_id",     :null => false
    t.datetime "created_at"
  end

  add_index "expertise_areas", ["category_id"], :name => "index_expertise_areas_on_category_id"
  add_index "expertise_areas", ["user_id"], :name => "index_expertise_areas_on_user_id"

  create_table "expertise_events", :force => true do |t|
    t.integer  "expertise_id",                 :null => false
    t.integer  "user_id",                      :null => false
    t.string   "event_type",   :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "faqs", :force => true do |t|
    t.text     "question"
    t.text     "answer"
    t.text     "categories"
    t.text     "states"
    t.text     "hardiness_zones"
    t.datetime "heureka_published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status"
    t.text     "age_ranges"
    t.text     "reference_questions"
    t.integer  "average_ranking",      :limit => 10, :precision => 10, :scale => 0
  end

  create_table "feed_locations", :force => true do |t|
    t.text     "uri",                          :null => false
    t.boolean  "active",     :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "help_feeds", :force => true do |t|
    t.string   "title"
    t.string   "etag"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "institutions", :force => true do |t|
    t.integer  "entrytype",                           :default => 0,  :null => false
    t.string   "location_abbreviation", :limit => 4
    t.string   "name",                                :default => "", :null => false
    t.string   "code",                  :limit => 10
    t.string   "uri"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "normalizedname"
    t.integer  "location_id",                         :default => 0
    t.integer  "created_by",                          :default => 0
    t.string   "creatorlogin"
    t.integer  "institutionalteam_id",                :default => 0
  end

  add_index "institutions", ["location_abbreviation"], :name => "STATE_ABBR"
  add_index "institutions", ["name"], :name => "NAME", :unique => true

  create_table "invitations", :force => true do |t|
    t.integer  "user_id",                      :default => 0,  :null => false
    t.string   "token",          :limit => 40, :default => "", :null => false
    t.string   "email",                        :default => "", :null => false
    t.datetime "created_at",                                   :null => false
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

  create_table "list_owners", :force => true do |t|
    t.string   "email",          :limit => 96
    t.integer  "list_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "moderator",                    :default => false
    t.boolean  "emailconfirmed",               :default => true
    t.integer  "user_id",                      :default => 0
    t.boolean  "ineligible",                   :default => false
  end

  add_index "list_owners", ["list_id", "email", "user_id"], :name => "list_email_user", :unique => true

  create_table "list_posts", :force => true do |t|
    t.datetime "posted_at"
    t.integer  "list_id",                   :default => 0
    t.string   "listname",    :limit => 50
    t.integer  "user_id",                   :default => 0
    t.string   "senderemail", :limit => 96
    t.integer  "size",                      :default => 0
    t.string   "messageid"
    t.string   "status"
    t.datetime "created_at"
  end

  add_index "list_posts", ["posted_at", "listname", "senderemail", "messageid"], :name => "unique_email", :unique => true

  create_table "list_subscriptions", :force => true do |t|
    t.string   "email",          :limit => 96
    t.integer  "list_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "listpassword"
    t.boolean  "digest",                       :default => false
    t.boolean  "suspended",                    :default => false
    t.boolean  "ineligible",                   :default => false
    t.integer  "user_id",                      :default => 0
    t.boolean  "emailconfirmed",               :default => true
    t.boolean  "optout",                       :default => false
  end

  add_index "list_subscriptions", ["list_id", "email", "user_id"], :name => "unique_subscription", :unique => true

  create_table "lists", :force => true do |t|
    t.string   "name",                     :limit => 50
    t.boolean  "deleted",                                :default => false
    t.boolean  "managed",                                :default => false
    t.boolean  "advertised",                             :default => true
    t.boolean  "private_archive",                        :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "dropforeignsubscriptions",               :default => false
    t.string   "password"
    t.boolean  "dropunconnected",                        :default => true
  end

  create_table "locations", :force => true do |t|
    t.integer "fipsid",                     :default => 0,  :null => false
    t.integer "entrytype",                  :default => 0,  :null => false
    t.string  "name",                       :default => "", :null => false
    t.string  "abbreviation", :limit => 10, :default => "", :null => false
  end

  add_index "locations", ["fipsid"], :name => "fipsid", :unique => true
  add_index "locations", ["name"], :name => "name", :unique => true

  create_table "locations_users", :id => false, :force => true do |t|
    t.integer "location_id", :default => 0, :null => false
    t.integer "user_id",     :default => 0, :null => false
  end

  add_index "locations_users", ["user_id", "location_id"], :name => "fk_locations_users", :unique => true

  create_table "metacommunityconnections", :force => true do |t|
    t.integer  "metacommunity_id"
    t.integer  "includedcommunity_id"
    t.string   "connectiontype"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "metacommunityconnections", ["connectiontype"], :name => "index_metacommunityconnections_on_connectiontype"
  add_index "metacommunityconnections", ["metacommunity_id", "includedcommunity_id"], :name => "meta_included", :unique => true

  create_table "notifications", :force => true do |t|
    t.integer  "notifytype",     :default => 0
    t.integer  "user_id",        :default => 0,     :null => false
    t.integer  "created_by",     :default => 0
    t.integer  "community_id",   :default => 0,     :null => false
    t.boolean  "sent_email",     :default => false
    t.boolean  "send_error",     :default => false
    t.datetime "sent_email_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "additionaldata"
  end

  add_index "notifications", ["send_error"], :name => "index_notifications_on_send_error"
  add_index "notifications", ["sent_email"], :name => "index_notifications_on_sent_email"

  create_table "open_id_associations", :force => true do |t|
    t.binary  "server_url",                 :null => false
    t.string  "handle",     :default => "", :null => false
    t.binary  "secret",                     :null => false
    t.integer "issued",                     :null => false
    t.integer "lifetime",                   :null => false
    t.string  "assoc_type", :default => "", :null => false
  end

  create_table "open_id_nonces", :force => true do |t|
    t.string  "server_url", :default => "", :null => false
    t.integer "timestamp",                  :null => false
    t.string  "salt",       :default => "", :null => false
  end

  create_table "opie_approvals", :force => true do |t|
    t.integer  "user_id",    :default => 0,  :null => false
    t.string   "trust_root", :default => "", :null => false
    t.datetime "created_at",                 :null => false
  end

  create_table "positions", :force => true do |t|
    t.integer  "entrytype",  :default => 0,  :null => false
    t.string   "name",       :default => "", :null => false
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

  create_table "pubsite_communities", :force => true do |t|
    t.string  "title"
    t.text    "description"
    t.boolean "visible",     :default => true
    t.integer "topic_id"
    t.string  "name"
  end

  create_table "pubsite_institutions", :force => true do |t|
    t.string  "state",       :limit => 4,  :default => "",    :null => false
    t.integer "location_id",               :default => 0,     :null => false
    t.string  "name",                      :default => "",    :null => false
    t.string  "code",        :limit => 10, :default => ""
    t.string  "uri",                       :default => ""
    t.string  "domain",                    :default => ""
    t.boolean "shared",                    :default => false
  end

  add_index "pubsite_institutions", ["code"], :name => "code"
  add_index "pubsite_institutions", ["domain"], :name => "domain_idx"
  add_index "pubsite_institutions", ["location_id"], :name => "fk_loc_id"
  add_index "pubsite_institutions", ["name"], :name => "NAME", :unique => true

  create_table "pubsite_taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
  end

  add_index "pubsite_taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "pubsite_taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

  create_table "pubsite_tags", :force => true do |t|
    t.string  "name"
    t.integer "community_id"
  end

  create_table "ratings", :force => true do |t|
    t.integer  "rating",                       :default => 0
    t.datetime "created_at",                                   :null => false
    t.string   "rateable_type",  :limit => 15, :default => "", :null => false
    t.integer  "rateable_id",                  :default => 0,  :null => false
    t.integer  "user_id",                      :default => 0
    t.string   "rateable_title"
  end

  add_index "ratings", ["user_id"], :name => "fk_ratings_user"

  create_table "roles", :force => true do |t|
    t.string "name"
  end

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

  create_table "submitted_question_events", :force => true do |t|
    t.string   "event_type"
    t.integer  "submitted_question_id"
    t.integer  "initiated_by"
    t.integer  "subject_user"
    t.datetime "created_at"
    t.text     "response"
    t.integer  "contributing_faq"
    t.string   "category"
    t.integer  "event_state",           :null => false
  end

  add_index "submitted_question_events", ["initiated_by"], :name => "initiated_by_idx"
  add_index "submitted_question_events", ["subject_user"], :name => "subject_user_idx"
  add_index "submitted_question_events", ["submitted_question_id"], :name => "submitted_question_id_idx"

  create_table "submitted_questions", :force => true do |t|
    t.integer  "resolved_by"
    t.integer  "submitted_by",             :default => 0,     :null => false
    t.integer  "current_contributing_faq"
    t.string   "status",                   :default => "",    :null => false
    t.text     "asked_question",                              :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.boolean  "duplicate",                :default => false, :null => false
    t.string   "external_app_id"
    t.string   "external_submitter"
    t.datetime "resolved_at"
    t.integer  "external_id"
    t.datetime "question_updated_at"
    t.text     "current_response"
    t.string   "resolver_email"
    t.string   "question_fingerprint",     :default => "",    :null => false
    t.string   "submitter_firstname",      :default => "",    :null => false
    t.string   "submitter_lastname",       :default => "",    :null => false
    t.integer  "county_id"
    t.integer  "location_id"
    t.boolean  "spam",                     :default => false, :null => false
    t.string   "user_ip",                  :default => "",    :null => false
    t.string   "user_agent",               :default => "",    :null => false
    t.string   "referrer",                 :default => "",    :null => false
    t.string   "widget_name"
    t.integer  "status_state",                                :null => false
  end

  add_index "submitted_questions", ["county_id"], :name => "fk_sq_county"
  add_index "submitted_questions", ["created_at"], :name => "created_at_idx"
  add_index "submitted_questions", ["current_contributing_faq"], :name => "fk_qu_sq"
  add_index "submitted_questions", ["location_id"], :name => "fk_sq_location"
  add_index "submitted_questions", ["question_fingerprint"], :name => "index_submitted_questions_on_question_fingerprint"
  add_index "submitted_questions", ["resolved_at"], :name => "resolved_at_idx"
  add_index "submitted_questions", ["resolved_by"], :name => "resolved_by_idx"
  add_index "submitted_questions", ["submitted_by"], :name => "submitted_by_idx"
  add_index "submitted_questions", ["user_id"], :name => "fk_usr_sq"
  add_index "submitted_questions", ["user_id"], :name => "user_id_idx"
  add_index "submitted_questions", ["widget_name"], :name => "index_submitted_questions_on_widget_name"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id",                                      :null => false
    t.integer  "taggable_id",                                 :null => false
    t.string   "taggable_type", :limit => 32
    t.string   "tag_kind",      :limit => 16
    t.string   "tag_display",                 :default => "", :null => false
    t.integer  "owner_id",                                    :null => false
    t.integer  "weight",                      :default => 1,  :null => false
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "tag_kind", "owner_id"], :name => "taggingindex", :unique => true

  create_table "tags", :force => true do |t|
    t.string   "name",       :default => "", :null => false
    t.datetime "created_at",                 :null => false
  end

  add_index "tags", ["name"], :name => "index_tags_on_name", :unique => true

  create_table "topics", :force => true do |t|
    t.string "name"
  end

  create_table "update_times", :force => true do |t|
    t.integer  "datasource_id"
    t.string   "datasource_type"
    t.string   "datatype"
    t.datetime "last_datasourced_at"
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
    t.string   "login",                        :default => "", :null => false
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
    t.integer  "user_id",                      :default => 0,  :null => false
    t.integer  "tokentype",                    :default => 0,  :null => false
    t.string   "token",          :limit => 40, :default => "", :null => false
    t.text     "tokendata"
    t.datetime "created_at",                                   :null => false
    t.datetime "expires_at",                                   :null => false
    t.datetime "extended_at"
    t.integer  "extended_count",               :default => 0
  end

  add_index "user_tokens", ["token"], :name => "tokenlookup"

  create_table "users", :force => true do |t|
    t.string   "login",                    :limit => 80, :default => "",    :null => false
    t.string   "password",                 :limit => 40, :default => "",    :null => false
    t.string   "first_name",                             :default => "",    :null => false
    t.string   "last_name",                              :default => "",    :null => false
    t.string   "email",                    :limit => 96
    t.string   "title"
    t.datetime "email_event_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "contributor_agreement"
    t.datetime "contributor_agreement_at"
    t.integer  "account_status"
    t.datetime "last_login_at"
    t.integer  "institution_id",                         :default => 0
    t.integer  "position_id",                            :default => 0
    t.integer  "location_id",                            :default => 0
    t.integer  "county_id",                              :default => 0
    t.boolean  "retired",                                :default => false
    t.boolean  "vouched",                                :default => false
    t.integer  "vouched_by",                             :default => 0
    t.datetime "vouched_at"
    t.boolean  "emailconfirmed",                         :default => false
    t.boolean  "is_staff",                               :default => false
    t.boolean  "is_admin",                               :default => false
    t.string   "phonenumber"
    t.string   "feedkey"
    t.boolean  "announcements",                          :default => true
    t.datetime "retired_at"
  end

  add_index "users", ["email"], :name => "email", :unique => true
  add_index "users", ["login"], :name => "login", :unique => true
  add_index "users", ["vouched", "retired"], :name => "index_users_on_vouched_and_retired"

  create_table "widgets", :force => true do |t|
    t.string   "name",        :default => "", :null => false
    t.string   "fingerprint", :default => "", :null => false
    t.string   "widget_url",  :default => "", :null => false
    t.string   "author",      :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
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
