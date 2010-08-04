class ChangeLearnConnectiontype < ActiveRecord::Migration
  def self.up
    remove_index(:learn_connections, ['learn_session_id','connectiontype'])
    change_column :learn_connections, :connectiontype, :integer
    add_index(:learn_connections, ['learn_session_id','connectiontype'])
  end

  def self.down
  end
end
