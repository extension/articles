class AddYearAnalytics < ActiveRecord::Migration
  def change
    create_table "year_analytics", :force => true do |t|
      t.integer  "page_id"
      t.text     "analytics_url"
      t.string   "url_type"
      t.integer  "url_page_id"
      t.string   "url_wiki_title"
      t.integer  "pageviews"
      t.integer  "unique_pageviews"
      t.date     "start_date"
      t.date     "end_date"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

  end

end
