class UpdateQuestionFingerprints < ActiveRecord::Migration
  def self.up
    ActiveRecord::Migration.verbose = false
    
    SubmittedQuestion.find(:all).each do |sq|
      appname = sq.external_app_id ? sq.external_app_id : 'unknown'
      submitter_email = sq.submitter_email ? sq.submitter_email : ''
      new_print = Digest::MD5.hexdigest(appname + sq.created_at.to_s + sq.asked_question + submitter_email + AppConfig.configtable['sessionsecret'])
      execute "UPDATE submitted_questions as sq SET question_fingerprint = '#{new_print}' WHERE sq.id = #{sq.id}"
    end
  end

  def self.down
  end
end
