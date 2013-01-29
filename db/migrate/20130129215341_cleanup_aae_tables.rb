class CleanupAaeTables < ActiveRecord::Migration
  def self.up
    drop_table "aae_emails"
    drop_table "categories"
    drop_table "categories_submitted_questions"
    drop_table "expertise_areas"
    drop_table "expertise_counties"
    drop_table "expertise_counties_users"
    drop_table "expertise_events"
    drop_table "expertise_locations"
    drop_table "expertise_locations_users"
    drop_table "roles"
    drop_table "submitted_question_events"
    drop_table "submitted_questions"
    drop_table "user_preferences"
    drop_table "user_roles"
    drop_table "widget_events"
    drop_table "widgets"

    # trash taggings
    execute "DELETE FROM taggings where taggable_type = 'SubmittedQuestion'"
    
    # trash notifications
    execute "DELETE FROM notifications where notifytype BETWEEN 1000 AND 2099"
  end

  def self.down
  end
end
