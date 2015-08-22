class AddImageData < ActiveRecord::Migration
  def change
    create_table "image_data", :force => true do |t|
      t.integer   "link_id",:null => true
      t.string    "filename",:null => true
      t.text      "path",:null => true
      t.integer   "source_id",:null => true
      t.string    "source",:null => true
      t.text      "description",:null => true
      t.text      "copyright",:null => true
    end
    add_index "image_data", ["link_id"], :name => "link_index"
    add_index "image_data", ["source_id","source"], :name => "source_id_index", :unique => true

  end
end
