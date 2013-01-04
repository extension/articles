class DropPublicUsers < ActiveRecord::Migration
  def self.up
    execute "DELETE FROM accounts WHERE type = 'PublicUser'"
  end
end
