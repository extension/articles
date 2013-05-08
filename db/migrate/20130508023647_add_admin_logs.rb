class AddAdminLogs < ActiveRecord::Migration
  def self.up
    create_table "admin_logs", :force => true do |t|
      t.integer  "person_id",                  :default => 0, :null => false
      t.integer  "event",                    :default => 0, :null => false
      t.string   "ip",         :limit => 20
      t.text     "data"
      t.datetime "created_at"
    end

    execute("INSERT INTO admin_logs select * from admin_events WHERE event >= 50 and event <= 64")
  end

  def self.down
  end
end
