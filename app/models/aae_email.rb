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
require "fetcher"
require 'hpricot'

class AaeEmail < ActiveRecord::Base
  
  belongs_to :account
  belongs_to :submitted_question

  NOTIFY_ADDRESS = 'aae-notify@extension.org'
  PUBLIC_ADDRESS = 'ask-an-expert@extension.org'
  ESCALATION_ADDRESS = 'aae-escalation@extension.org'
  NOREPLY_ADDRESS = 'aae-noreply@extension.org'
  
  # email destination
  PUBLIC = 'public'
  EXPERT = 'expert'
  ESCALATION = 'escalation'
  NOREPLY = 'noreply'
  UNKNOWN = 'unknown'
  
  # reply type
  NEW_QUESTION = 'new question'
  PUBLIC_REPLY = 'public reply'
  # only relevant to experts
  REASSIGN_REPLY = 'reassign reply'
  ASSIGN_REPLY = 'assign reply'
  EDIT_REPLY = 'edit reply'
  REJECT_REPLY = 'reject reply'
  ESCALATION_REPLY = 'reply'
  COMMENT_REPLY = 'comment reply'
  OTHER_REPLY = 'other reply'
  # and all else
  UNKNOWN_EMAIL = 'unknown'
  
  # email types
  VACATION = 'vacation'
  BOUNCE = 'bounce'
  DIRECT = 'direct'
  
  # code for multiple assigns/submits
  MULTI_QUESTION = 0
  
  # actions
  IGNORED = 'ignored'
  REJECTED = 'rejected'
  COMMENTED = 'commented'
  REASSIGNED = 'reassigned'
  FAILURE = "unable to process"
  REPLIED = "replied"
  
  named_scope :unhandled, :conditions => "action_taken IS NULL or action_taken = 'unhandled'"
  named_scope :vacations, :conditions => "vacation = 1"
  named_scope :bounces, :conditions => "bounced = 1"
  named_scope :escalations, :conditions => "destination = '#{ESCALATION}'"
  named_scope :experts, :conditions => "destination = '#{EXPERT}'"
  named_scope :publics, :conditions => "destination = '#{PUBLIC}'"
  named_scope :public_replies, :conditions => "destination = '#{PUBLIC}' and reply_type = '#{PUBLIC_REPLY}'"
  named_scope :public_questions, :conditions => "destination = '#{PUBLIC}' and reply_type = '#{NEW_QUESTION}'"
  
  def self.receive(email)  
    mail = Mail.read_from_string(email)
    mail.charset='UTF-8'
    mail_bounced = mail.bounced? ? true : false
    
    if(email_address = EmailAddress.new(mail.from[0]))
      from_address = mail.from[0]
    end
    
    if(mail_bounced)
      # try to get the address from the final recipient
      if(mail.final_recipient)
        (spec,email_string) = mail.final_recipient.split(';')
        email_string.strip!
        if(email_address = EmailAddress.new(email_string))
          from_address = email_string
        end
      end
    end    
    
    logged_attributes = {:from => from_address, :to => mail.to.join(','), :subject => mail.subject, :message_id => mail.message_id, :mail_date => mail.date, :bounced => mail_bounced, :raw => mail.to_s}
    
    if(mail_bounced)
      logged_attributes.merge!({:bounce_code => mail.error_status, :bounce_diagnostic => mail.diagnostic_code, :retryable => mail.retryable?})
    end
    
    # check the subject line for a question id, if we get one, let's use it
    if(mail.subject =~ /.*\[eXtension Question:\s*(\d+)\s*\]/)
      squid = $1
      if(submitted_question = SubmittedQuestion.find_by_id(squid))
        logged_attributes[:submitted_question_id] = submitted_question.id
      end
    end
    
    # vacation?
    if(self.is_vacation?(mail))
      is_vacation = true
      logged_attributes[:vacation] = true
    else
      is_vacation = false
    end
    
    logged_attributes[:reply_type] = UNKNOWN_EMAIL
    
    # figure out destination
    if(mail.to.include?(PUBLIC_ADDRESS))
      logged_attributes[:destination] = PUBLIC
      if(submitted_question or mail_bounced or is_vacation)
        logged_attributes[:reply_type] = PUBLIC_REPLY
      else 
        # assume new question
        logged_attributes[:reply_type] = NEW_QUESTION
      end        
    elsif(mail.to.include?(NOTIFY_ADDRESS))
      logged_attributes[:destination] = EXPERT
      # figure out some other attributes if we have them - was this a reassign response, etc.
      if(mail.subject =~ /question reassigned/)
        logged_attributes[:reply_type] = REASSIGN_REPLY
      elsif(mail.subject =~ /question rejected/)
        logged_attributes[:reply_type] = REJECT_REPLY
      elsif(mail.subject =~ /question assigned/)
        logged_attributes[:reply_type] = ASSIGN_REPLY
      elsif(mail.subject =~ /question edited/)
        logged_attributes[:reply_type] = EDIT_REPLY
      elsif(mail.subject =~ /comment/)
        logged_attributes[:reply_type] = COMMENT_REPLY
      else
        logged_attributes[:reply_type] = OTHER_REPLY
      end
    elsif(mail.to.include?(ESCALATION_ADDRESS))
      logged_attributes[:destination] = ESCALATION
      logged_attributes[:reply_type] = ESCALATION_REPLY
    elsif(mail.to.include?(NOREPLY_ADDRESS))
      logged_attributes[:destination] = NOREPLY
    else
      logged_attributes[:destination] = UNKNOWN
    end  
  
        
    # find account
    if(email_address)
      if(account = Account.find_by_email(email_address))
        logged_attributes[:account_id] = account.id
      elsif(submitted_question)
        # let's cheat and get the account from the question
        case logged_attributes[:destination]
        when PUBLIC
          # todo - probably should sanity check email with submitter.email (domain or whatever), this could
          # be a response to the question from another person?  But the odds of different emails with the
          # public are a lot lower than with the experts
          if(submitted_question.submitter)
            account = submitted_question.submitter
            logged_attributes[:account_id] = account.id
          end
        when EXPERT
          if((logged_attributes[:reply_type] == ASSIGN_REPLY) or (logged_attributes[:reply_type] == EDIT_REPLY) or (logged_attributes[:reply_type] == REJECT_REPLY))
            if(submitted_question.assignee)
              assignee_email = EmailAddress.new(submitted_question.assignee.email)
              if((assignee_email.base_domain == email_address.base_domain) or (assignee_email.local == email_address.local))
                account = submitted_question.assignee
                logged_attributes[:account_id] = account.id
              end
            end
          elsif(logged_attributes[:reply_type] == REASSIGN_REPLY)
            # todo - get the last reasssign event, and hope that's it
          end
        end
      end
    
      if(!account)
        # let's try to get a little cuter with this
        # get the user@host - and search like that
        if(accounts = Account.patternsearch(email_address.local).all(:conditions => "email like '%#{email_address.base_domain}%'"))
          if(accounts.size == 1)
            # found match!
            account = accounts[0]
            logged_attributes[:account_id] = account.id
          else # hmmm, we found multiple accounts - we need to probably to do something
            # todo: do something
          end
        end
      end    
    end # had a valid email address
        
    # get submitted or assigned question - this is a best guess deal, may not be accurate.
    if(account and submitted_question.blank?)
      if(logged_attributes[:destination] == PUBLIC)
        if(submitted_question = account.submitted_questions.first(:order => 'updated_at DESC'))
          logged_attributes[:submitted_question_id] = submitted_question.id
        end
      elsif(logged_attributes[:destination] == EXPERT and account.class == User)
        if(submitted_question = account.assigned_questions.first(:order => 'updated_at DESC'))
          logged_attributes[:submitted_question_id] = submitted_question.id
        end
      end
    end
    
    # attachements?
    if(!mail.attachments.blank?)
      logged_attributes[:attachments] = true
    else
      logged_attributes[:attachments] = false
    end
    
    self.create(logged_attributes)
  end
  
  def original_email
    Mail.read_from_string(self.raw)
  end
  
  def plain_text_message
    mail = self.original_email
    if(mail.multipart?)
      if(mail.parts[0].multipart?)
        if(mail.parts[0].parts[0].multipart?)
          # give up
          return ''
        else
          Hpricot(mail.parts[0].parts[0].decoded).to_plain_text
        end
      else
        Hpricot(mail.parts[0].decoded).to_plain_text
      end
    else
      Hpricot(mail.body.decoded).to_plain_text
    end
  end
  
  def email_response
    plain_text_response = self.plain_text_message
    (comment,original) = plain_text_message.split(/-+\s*original\s*message\s*-+/i)
    if(!original)
      (comment,original) = plain_text_message.split(/From:.*<ask-an-expert@extension.org>/i)
    end
    if(!original)
      (comment,original) = plain_text_message.split(/<ask-an-expert@extension.org>/i)
    end
    return comment
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
  
  def self.fetch_email
    fetcher = Fetcher.create(self.fetcher_config)
    fetcher.fetch
  end
  

  ###########################################################
  # base regex's from http://github.com/whatcould/bounce-email
  # Copyright (c) 2009 Agris Ameriks
  #
  # will catch spamblocks too - well some spam blocks - others look like email responses
  def self.is_vacation?(mail)
    if(!mail.bounced?)
      return true if mail.subject.match(/auto.*reply|vacation|vocation|(out|away).*office|on holiday|abwesenheits|autorespond|Automatische|eingangsbestätigung/i)
      return true if mail['precedence'].to_s.match(/auto.*(reply|replied|responder|antwort)/i)
      return true if mail['auto-submitted'].to_s.match(/auto.*(reply|replied|responder|antwort)/i)
      # try to match the body as well
      plain_body = Hpricot(mail.body.decoded).to_plain_text
      return true if plain_body.match(/boxbe|auto.*reply|vacation|vocation|(out|away).*office|on holiday|abwesenheits|autorespond|Automatische|eingangsbestätigung/i)
    end
    false
  end

  

    
end
