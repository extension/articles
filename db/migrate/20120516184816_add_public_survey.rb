class AddPublicSurvey < ActiveRecord::Migration
  def self.up
    create_table "aae_public_surveys", :force => true do |t|
      t.integer  "user_id"
      t.integer  "peer_review"
      t.integer  "public_comment"
    end
    
    add_index "aae_public_surveys", ['user_id'], :name => 'survey_ndx', :unique => true    
  end

  def self.down
    drop_table "aae_public_surveys"
  end
end
