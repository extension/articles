class CreateAaeEmailTable < ActiveRecord::Migration
  def self.up
    create_table "aae_emails", :force => true do |t|
      t.integer  "submitted_question_id"
      t.string   "from"
      t.string   "to"
      t.string   "subject"
      t.string   "message_id"
      t.datetime "mail_date"
      t.boolean  "attachments",  :default => false
      t.boolean  "bounced",  :default => false
      t.string   "bounce_code"
      t.string   "bounce_type"
      t.text     "bounce_reason"
      t.datetime "created_at"
    end
  end

  def self.down
    drop_table "aae_emails"
  end
end
