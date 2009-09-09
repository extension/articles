class AddAdditionalDataToSqEvents < ActiveRecord::Migration
  def self.up
    add_column :submitted_question_events, :additionaldata, :text, :null => true
  end

  def self.down
    remove_column :submitted_question_events, :additionaldata
  end
end
