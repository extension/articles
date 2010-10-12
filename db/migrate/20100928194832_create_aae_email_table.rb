class CreateAaeEmailTable < ActiveRecord::Migration
  def self.up
    create_table "aae_emails", :force => true do |t|
      t.string   "from"
      t.string   "to"
      t.string  "destination"
      t.string   "subject"
      t.string   "message_id"
      t.datetime "mail_date"
      t.boolean  "attachments",  :default => false
      t.boolean  "bounced",  :default => false
      t.boolean  "vacation",  :default => false
      t.string   "bounce_code"
      t.string   "bounce_diagnostic"
      t.text     "raw",                 :limit => 16777215
      t.integer  "submitted_question_id"
      t.string   "submitted_question_ids"
      t.integer  "account_id"
      t.datetime "created_at"
    end
  end

  def self.down
    drop_table "aae_emails"
  end
end
