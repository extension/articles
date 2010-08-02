class LearnIndexes < ActiveRecord::Migration
  def self.up
    add_index(:learn_sessions, ['session_start','session_end'])
    add_index(:learn_connections, ['learn_session_id','connectiontype'])
    add_index(:learn_connections, ['user_id','public_user_id'])
  end

  def self.down
    remove_index(:learn_sessions, ['session_start','session_end'])
    remove_index(:learn_connections, ['learn_session_id','connectiontype'])
    remove_index(:learn_connections, ['user_id','public_user_id'])
  end
end
