class CopyWikiDinoTables < ActiveRecord::Migration
  def self.up

    create_table "bronto_deliveries", :force => true, :id => false do |t|
      t.string   "id", :null => false
      t.string   "bronto_message_id",  :null => false
      t.string   "status",  :null => false
      t.datetime "start",  :null => false
      t.timestamps
    end
    execute "ALTER table bronto_deliveries ADD PRIMARY KEY (id)"
    execute "INSERT into bronto_deliveries SELECT id, messageId, status, start, NOW(),NOW() from prod_copwiki.wikidino_deliveries"
    
    
    create_table "bronto_messages", :force => true, :id => false do |t|
      t.string   "id", :null => false
      t.string   "message_name",  :null => true
      t.boolean  "is_jitp", :null => true
      t.datetime "last_updated_at", :null => true
      t.timestamps
    end
    
    execute "ALTER table bronto_messages ADD PRIMARY KEY (id)"
    execute "INSERT into bronto_messages SELECT DISTINCT(message_id), message_name, 1, NOW(),NOW(),NOW() from prod_copwiki.wikidino_sends group by message_id"
    
    create_table "bronto_recipients", :force => true, :id => false do |t|
      t.string   "id", :null => false
      t.string   "email",  :null => true
      t.datetime "last_updated_at", :null => true
      t.timestamps
    end
    
    execute "ALTER table bronto_recipients ADD PRIMARY KEY (id)"
    execute "INSERT into bronto_recipients SELECT DISTINCT(user_id), user_email, NOW(),NOW(),NOW() from prod_copwiki.wikidino_sends  group by user_id"
    
    
    create_table "bronto_sends", :force => true do |t|
      t.string   "bronto_delivery_id", :null => false
      t.string   "bronto_message_id",  :null => false
      t.string   "bronto_recipient_id", :null => false
      t.datetime "sent",       :null => false
      t.string   "url", :null => true
      t.datetime "clicked", :null => true
      t.timestamps
    end
    
    add_index('bronto_clicks',['bronto_delivery_id','bronto_message_id','bronto_recipient_id'], :unique => true)
    execute "INSERT into bronto_sends (bronto_delivery_id,bronto_message_id,bronto_recipient_id,sent,updated_at,created_at) SELECT delivery_id,message_id,user_id,created,NOW(),NOW() from prod_copwiki.wikidino_sends"
    execute "UPDATE bronto_sends,prod_copwiki.wikidino_clicks SET bronto_sends.url = prod_copwiki.wikidino_clicks.url, clicked = prod_copwiki.wikidino_clicks.created WHERE bronto_recipient_id = prod_copwiki.wikidino_clicks.user_id AND bronto_sends.bronto_delivery_id = prod_copwiki.wikidino_clicks.delivery_id"
    
  end

  def self.down
    drop_table('bronto_deliveries')
    drop_table('bronto_messages')
    drop_table('bronto_recipients')
    drop_table('bronto_sends')
  end
end
