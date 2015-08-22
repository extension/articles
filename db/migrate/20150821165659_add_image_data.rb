class AddImageData < ActiveRecord::Migration
  def change
    create_table "image_data", :force => true do |t|
      t.string    "filename",:null => true
      t.text      "path",:null => true
      t.integer   "source_id",:null => true
      t.string    "source",:null => true
      t.text      "description",:null => true
      t.text      "copyright",:null => true
    end
    add_index "image_data", ["source_id","source"], :name => "source_id_index", :unique => true

    create_table "image_data_links", :force => true do |t|
      t.integer   "link_id",:null => false
      t.string    "image_data_id",:null => false
    end
    add_index "image_data_links", ["link_id","image_data_id"], :name => "link_index", :unique => true


  end
end
