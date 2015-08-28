class AddAuditTables < ActiveRecord::Migration
  def change

    create_table "hosted_image_audits", :force => true do |t|
      t.integer   "hosted_image_id",:null => false
      t.boolean   "is_stock", :null => false, :default => false
      t.integer   "is_stock_by", :null => true
      t.boolean   "community_reviewed", :null => false, :default => false
      t.integer   "community_reviewed_by", :null => true
      t.boolean   "staff_reviewed", :null => false, :default => false
      t.integer   "staff_reviewed_by", :null => true
      t.text      "notes",:null => true
    end
    add_index "hosted_image_audits", ["hosted_image_id"], :name => "image_ndx", :unique => true

    create_table "page_audits", :force => true do |t|
      t.integer   "page_id",:null => false
      t.boolean   "keep_published", :null => false, :default => true
      t.integer   "keep_published_by", :null => true
      t.boolean   "community_reviewed", :null => false, :default => false
      t.integer   "community_reviewed_by", :null => true
      t.boolean   "staff_reviewed", :null => false, :default => false
      t.integer   "staff_reviewed_by", :null => true
      t.text      "notes",:null => true
    end
    add_index "page_audits", ["page_id"], :name => "page_ndx", :unique => true

    create_table "audit_logs", :force => true do |t|
      t.string  "auditable_type",:null => false
      t.integer "auditable_id",:null => false
      t.integer "contributor_id",:null => false
      t.string  "changed_item",:null => false
      t.boolean  "previous_check_Value",:null => true
      t.text     "previous_notes",:null => true
      t.text     "current_notes",:null => true
    end

    add_index "audit_logs", ["auditable_type","auditable_id","contributor_id"], :name => "audit_ndx", :unique => true


  end

end
