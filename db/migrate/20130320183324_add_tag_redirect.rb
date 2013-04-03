class AddTagRedirect < ActiveRecord::Migration
  def self.up
    create_table "category_tag_redirects", :force => true do |t|
      t.string   "term"
      t.string   "target_url"
    end

    add_index "category_tag_redirects", ["term"], :name => "name_ndx", :unique => true

    CategoryTagRedirect.reset_column_information
    CategoryTagRedirect.create(:term => 'ecop', :target_url => 'http://www.aplu.org/Page.aspx?pid=291')
    CategoryTagRedirect.create(:term => 'agsafety', :target_url => 'http://www.extension.org/farm_safety_and_health')
  end

  def self.down
  end
end
