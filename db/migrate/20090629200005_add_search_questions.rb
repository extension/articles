class AddSearchQuestions < ActiveRecord::Migration
  def self.up
    create_table "search_questions", :force => true, :options => 'ENGINE=MyISAM DEFAULT CHARSET=utf8' do |t|
      t.integer  "entrytype"
      t.integer  "foreignid"
      t.integer  "foreignrevision",                             :default => 0
      t.string   "source"
      t.string   "sourcewidget"
      t.string   "displaytitle"
      t.text     "fulltitle"
      t.text     "content",                 :limit => 16777215
      t.string   "status"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "search_questions", ["entrytype", "foreignid"], :name => "recordsignature", :unique => true
    execute 'ALTER TABLE `search_questions` ADD FULLTEXT `title_content_full_index` (`fulltitle` ,`content`)'    
  end

  def self.down
  end
end
