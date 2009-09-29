class DropSqeEventType < ActiveRecord::Migration
  def self.up
    remove_column :submitted_question_events, :event_type
  end

  def self.down
  end
end
