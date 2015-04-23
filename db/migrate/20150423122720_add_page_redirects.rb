class AddPageRedirects < ActiveRecord::Migration
  def change
    create_table "page_redirects", :force => true do |t|
      t.integer   "page_id",:null => false
      t.integer   "redirect_page_id",:null => false
      t.string    "reason",:null => true
    end
    add_index "page_redirects", ["redirect_page_id"], :name => "redirect_page_index", :unique => true
  end

end
