class CleanupRoles < ActiveRecord::Migration
  def self.up
    execute "DELETE from roles where roles.name = 'Administrator'"
    execute "DELETE from user_roles where user_roles.role_id = 1"
  end

  def self.down
  end
end
