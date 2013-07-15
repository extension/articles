class DropBrontoData < ActiveRecord::Migration
  def self.up
    drop_table('bronto_deliveries')
    drop_table('bronto_messages')
    drop_table('bronto_recipients')
    drop_table('bronto_sends')
  end

end
