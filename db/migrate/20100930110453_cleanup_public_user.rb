class CleanupPublicUser < ActiveRecord::Migration
  def self.up
    # learn sessions - unused public_user
    remove_index(:learn_connections, ['user_id','public_user_id'])
    remove_column(:learn_connections, :public_user_id)
    
    # responses
    rename_column(:responses, :user_id, :resolver_id)
    rename_column(:responses, :public_user_id, :submitter_id)
    add_index(:responses, ["submitter_id"])
    execute "UPDATE responses,public_users,accounts SET responses.submitter_id = accounts.id WHERE responses.submitter_id = public_users.id AND public_users.email = accounts.email"
    
    # sqe
    rename_column(:submitted_question_events, :public_user_id, :submitter_id)
    add_index(:submitted_question_events, ["submitter_id"])
    execute "UPDATE submitted_question_events,public_users,accounts SET submitted_question_events.submitter_id = accounts.id WHERE submitted_question_events.submitter_id = public_users.id AND public_users.email = accounts.email"
    
    # sq
    remove_index(:submitted_questions, ['public_user_id'])
    rename_column(:submitted_questions, :public_user_id, :submitter_id)
    add_index(:submitted_questions, ["submitter_id"])
    execute "UPDATE submitted_questions,public_users,accounts SET submitted_questions.submitter_id = accounts.id WHERE submitted_questions.submitter_id = public_users.id AND public_users.email = accounts.email"

    
  end

  def self.down
  end
end
