class AddPageRedirection < ActiveRecord::Migration
  def change
    add_column(:pages, :redirect_page, :boolean, :default => false)
    add_column(:pages, :redirect_url, :text)

    add_index "pages", ["datatype","redirect_page"], :name => "index_pages_on_redirect_page_and_datatype"

    # create log table
    create_table "page_redirect_logs", :force => true do |t|
      t.integer  "person_id",                :default => 0, :null => false
      t.integer  "event",                    :default => 0, :null => false
      t.string   "ip",         :limit => 20
      t.text     "data"
      t.datetime "created_at"
    end

  end
end
