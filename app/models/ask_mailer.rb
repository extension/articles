# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class AskMailer < ActionMailer::Base
  
  if !AppConfig.configtable['send_aae_emails']
    ActionMailer::Base.perform_deliveries = false
  else
    ActionMailer::Base.perform_deliveries = true
  end

  def assigned(submitted_question, url, host = 'www.extension.org', sent_at = Time.now)
    @subject    =  host.to_s + ': Incoming question assigned to you'
    @body["submitted_question"] = submitted_question
    @body["question_url"] = url
    @body["assigned_at"] = sent_at
    @body["host"] = host
    @recipients = submitted_question.assignee.email
    @from       = 'noreplies@extension.org'
    @sent_on    = sent_at
    if(!AppConfig.configtable['mail_system_bcc'].nil? and !AppConfig.configtable['mail_system_bcc'].empty?)
      @bcc            = AppConfig.configtable['mail_system_bcc']
    end
    @headers    = {}
  end
  
  def reassign_notification(submitted_question, url, previous_assignee, host = 'faq.extension.org', sent_at = Time.now)
    @subject    =  host.to_s + ': Incoming question reassigned'
    @body["submitted_question"] = submitted_question
    @body["question_url"] = url
    @body["assigned_at"] = sent_at
    @recipients = previous_assignee
    @from       = 'noreplies@extension.org'
    @sent_on    = sent_at
    if(!AppConfig.configtable['mail_system_bcc'].nil? and !AppConfig.configtable['mail_system_bcc'].empty?)
      @bcc            = AppConfig.configtable['mail_system_bcc']
    end
    @headers    = {}
  end
  
  def escalation(recipients, submitted_questions, report_url, host = 'faq.extension.org', sent_at = Time.now)
    @subject = host.to_s + ': Ask an Expert Escalation Report'
    @body["submitted_questions"] = submitted_questions
    @body["report_url"] = report_url
    @body["host"] = host
    @recipients = recipients
    @from = "noreplies@extension.org"
    @sent_on = sent_at
    if(!AppConfig.configtable['mail_system_bcc'].nil? and !AppConfig.configtable['mail_system_bcc'].empty?)
      @bcc            = AppConfig.configtable['mail_system_bcc']
    end
    @headers = {}
  end
end
