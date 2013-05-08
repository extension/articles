class AddPeople < ActiveRecord::Migration
  def self.up
  
    create_table "people", :force => true do |t|
      t.string   "uid"
      t.string   "first_name"
      t.string   "last_name"
      t.boolean  "is_admin", :default => false
      t.boolean  "retired"
      t.datetime "last_active_at"
      t.timestamps
    end

    execute("INSERT INTO people (id,uid,first_name,last_name,is_admin,retired,created_at,updated_at) SELECT id,CONCAT('https://people.extension.org/',login),first_name,last_name,is_admin,retired,created_at,updated_at FROM accounts WHERE accounts.vouched = 1")
  end

  def self.down
  end
end
