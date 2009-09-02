class CreatePublicUser < ActiveRecord::Migration
  def self.up
    
    # new public user table
    create_table "public_users", :force => true do |t|
      t.string   "email",                                  :null => false
      t.string   "first_name",                             :default => ""
      t.string   "last_name",                              :default => ""
      t.string   "password",                               :default => ""
      t.string   "salt",                                   :default => ""
      t.boolean  "enabled",                           :default => true
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    add_index "public_users", "email", :unique => true
            
    # create entries from submitted_questions table
    execute "INSERT IGNORE INTO public_users (email, first_name, last_name, enabled, created_at, updated_at) SELECT LOWER(submitter_email), submitter_firstname, submitter_lastname, 1, NOW(), NOW() from submitted_questions WHERE submitter_email IS NOT NULL group by submitter_email"
    
    # add public_user_id to submitted_questions
    add_column(:submitted_questions, :public_user_id, :integer, :default => 0)
    add_index "submitted_questions", "public_user_id"
    
    # go back and associate with the new public_user records
    execute "UPDATE public_users,submitted_questions SET submitted_questions.public_user_id = public_users.id WHERE submitted_questions.submitter_email = public_users.email"
    
    # identify the spammers
    execute "UPDATE public_users, (SELECT public_users.id as userid, count(submitted_questions.id) as question_count, SUM(submitted_questions.spam) as spam_count from public_users,submitted_questions WHERE submitted_questions.public_user_id = public_users.id GROUP BY public_users.email HAVING spam_count > 0) as spammer_list SET public_users.enabled = 0 WHERE public_users.id = spammer_list.userid"
  end

  def self.down
  end
end
