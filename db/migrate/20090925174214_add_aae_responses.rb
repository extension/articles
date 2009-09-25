class AddAaeResponses < ActiveRecord::Migration
  def self.up
    create_table :responses do |t|
      t.integer :user_id, :public_user_id, :null => true
      t.integer :submitted_question_id, :null => false
      t.text :response, :null => false
      t.datetime :duration_since_last, :null => false
      t.boolean :sent, :null => false, :default => false
      t.timestamps
    end
    
    add_index(:responses, :submitted_question_id)
    add_index(:responses, :user_id)
  end

  def self.down
    drop_table :responses
  end
end
