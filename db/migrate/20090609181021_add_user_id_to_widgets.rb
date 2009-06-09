class AddUserIdToWidgets < ActiveRecord::Migration
  def self.up
    add_column :widgets, :user_id, :integer, :null => false
    execute "Update widgets as w join users as u on w.author = u.login SET w.user_id = u.id"
  end

  def self.down
    remove_column :widgets, :user_id
  end
end
