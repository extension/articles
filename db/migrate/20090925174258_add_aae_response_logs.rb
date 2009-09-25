class AddAaeResponseLogs < ActiveRecord::Migration
  def self.up
    create_table :response_logs do |t|
      t.integer :user_id, :public_user_id, :null => true
      t.integer :submitted_question_id, :response_id, :null => false
      t.text :response, :null => false
      t.boolean :sent, :null => false, :default => false
      t.datetime :created_at
    end
    
    add_index(:response_logs, :submitted_question_id)
    add_index(:response_logs, :response_id)
    add_index(:response_logs, :user_id)
  end

  def self.down
    drop_table :response_logs
  end
end
