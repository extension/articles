class DropSearchQuestions < ActiveRecord::Migration
  def self.up
    drop_table(:search_questions)
  end

  def self.down
  end
end
