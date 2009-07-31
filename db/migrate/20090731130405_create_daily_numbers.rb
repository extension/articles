class CreateDailyNumbers < ActiveRecord::Migration
  def self.up
    create_table "daily_numbers", :force => true do |t|
      t.integer  "datasource_id"
      t.string   "datasource_type"
      t.date     "datadate"
      t.string   "datatype"
      t.integer  "total"
      t.integer  "thatday"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "additionaldata"
    end
  end

  def self.down
  end
end
