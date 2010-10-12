# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

# Vacation Regex processing adapted from
# http://github.com/whatcould/bounce-email
# Copyright (c) 2009 Agris Ameriks

require "mail"

class AaeEmail < ActiveRecord::Base

  NOTIFY_ADDRESS = 'aaenotify@extension.org'
  PUBLIC_ADDRESS = 'ask-an-expert@extension.org'
  ESCALATION_ADDRESS = 'aae-escalation@extension.org'
  
  # email destination
  PUBLIC = 'public'
  EXPERT = 'expert'
  ESCALATION = 'escalation'
  UNKNOWN = 'unknown'
  
  # email types
  VACATION = 'vacation'
  BOUNCE = 'bounce'
  DIRECT = 'direct'
  
  # code for multiple assigns/submits
  MULTI_QUESTION = 0
  
  
  def self.receive(email)
    mail = Mail.read_from_string(email)
    mail.charset='UTF-8'
    mail_bounced = mail.bounced? ? true : false
    logger.info("Got mail! #{mail.subject} #{mail.from} #{mail.to} #{mail.message_id} #{mail.date} #{mail_bounced}")
    
    from_address = mail.from[0]  
    if(mail_bounced)
      # try to get the address from the final recipient
      if(mail.final_recipient)
        (spec,email_string) = mail.final_recipient.split(';')
        from_address = email_string.strip
      end
    end        
    
    logged_attributes = {:from => from_address, :to => mail.to.join(','), :subject => mail.subject, :message_id => mail.message_id, :mail_date => mail.date, :bounced => mail_bounced, :raw => mail.to_s}
    
    if(mail_bounced)
      logged_attributes.merge!({:bounce_code => mail.error_status, :bounce_diagnostic => mail.diagnostic_code})
    end
    
    # figure out destination
    if(mail.to.include?(PUBLIC_ADDRESS))
      logged_attributes[:destination] = PUBLIC
    elsif(mail.to.include?(NOTIFY_ADDRESS))
      if(mail.subject =~ /Escalation Report/)
        logged_attributes[:destination] = ESCALATION
      else
        logged_attributes[:destination] = EXPERT
      end
    else
      logged_attributes[:destination] = UNKNOWN
    end  
    
    # vacation?
    if(self.is_vacation?(mail))
      logged_attributes[:vacation] = true
    end
    

    
    # find account
    if(account = Account.find_by_email(from_address))
      logged_attributes[:account_id] = account.id
    end
    
    # get submitted or assigned questions
    if(account)
      if(logged_attributes[:destination] = PUBLIC)
        if(submitted_questions = account.submitted_questions.submitted)
          if(submitted_questions.size == 1)
            logged_attributes[:submitted_question_id] = submitted_questions[0].id
          else
            logged_attributes[:submitted_question_id] = MULTI_QUESTION
            logged_attributes[:submitted_question_ids] = submitted_questions.map(&:id).join(',')
          end
        end
      elsif(logged_attributes[:destination] = EXPERT)
        if(assigned_questions = account.assigned_questions.submitted)
          if(assigned_questions.size == 1)
            logged_attributes[:submitted_question_id] = assigned_questions[0].id
          else
            logged_attributes[:submitted_question_id] = MULTI_QUESTION
            logged_attributes[:submitted_question_ids] = assigned_questions.map(&:id).join(',')
          end
        end
      end
    end

      
    self.create(logged_attributes)
  end
  
  
  
  def self.fetcher_config
    {:type => :imap,
      :server => 'imap.gmail.com',
      :port => 993,
      :ssl => true,      
      :username => AppConfig.configtable['googleapps_aaemailer'],
      :password => AppConfig.configtable['googleapps_aaemailer_secret'],
      :use_login => true,
      :processed_folder => 'processed',
      :receiver => AaeEmail}
  end
  
  ###########################################################
  # base regex's from http://github.com/whatcould/bounce-email
  # Copyright (c) 2009 Agris Ameriks
  #
  # will catch spamblocks too
  def self.is_vacation?(mail)
    if(!mail.bounced?)
      return true if mail.subject.match(/auto.*reply|vacation|vocation|(out|away).*office|on holiday|abwesenheits|autorespond|Automatische|eingangsbestätigung/i)
      return true if mail['precedence'].to_s.match(/auto.*(reply|replied|responder|antwort)/i)
      return true if mail['auto-submitted'].to_s.match(/auto.*(reply|replied|responder|antwort)/i)
    end
    false
  end

  

    
end
