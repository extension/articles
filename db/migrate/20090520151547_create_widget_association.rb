class CreateWidgetAssociation < ActiveRecord::Migration
  def self.up
    add_column :submitted_questions, :widget_id, :integer, :null => true
    
    # fill in widget associations for questions from widgets 
    # using the existing widget names
    execute('UPDATE submitted_questions as sq JOIN widgets as w on TRIM(sq.widget_name) = TRIM(w.name) SET sq.widget_id = w.id')
  end

  def self.down
    remove_column :submitted_questions, :widget_id
  end
end
