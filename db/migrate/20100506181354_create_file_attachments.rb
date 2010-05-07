class CreateFileAttachments < ActiveRecord::Migration
  def self.up
    create_table "file_attachments", :force => true do |t|
      t.string :attachment_file_name
      t.string :attachment_content_type
      t.integer :attachment_file_size
      t.datetime :attachment_updated_at
      t.integer :submitted_question_id
      t.timestamps
    end
  end

  def self.down
    drop_table :file_attachments
  end
end
