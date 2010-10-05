# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require "tmail"
require "bounce_email"

class AaeEmail < ActiveRecord::Base

  NOTIFY_ADDRESS = 'aaenotify@extension.org'
  PUBLIC_ADDRESS = 'ask-an-expert@extension.org'
  
  def self.receive(email)
    mail = TMail::Mail.parse(email)
    bounce = BounceEmail::Mail.new(mail)
    logger.info("Got mail! #{mail.subject} #{mail.from} #{mail.to} #{mail.message_id} #{mail.date} #{bounce.is_bounce?}")
    
    # was this a bounce?
    if(bounce.is_bounce?)
      logger.info("=-=-=-=-=-= Processing bounce email.")      
      # public?
      if(mail.to.include?(PUBLIC_ADDRESS))
        logger.info("=-=-=-=-=-= Processing public bounce #{bounce.type}.")
        from_address = mail.from[0]
        # find account
        if(account = Account.find_by_email(from_address))
          logger.info("=-=-=-=-=-= Found account match - Account ID #{account.id}.")
          if(submitted_questions = account.submitted_questions)
            logger.info("=-=-=-=-=-= Found #{submitted_questions.size} submitted questions.")
          else
            logger.info("=-=-=-=-=-= WARNING - found no submitted questions!")
          end
        else
          logger.info("=-=-=-=-=-= WARNING found no account match! - #{from_address}.")
        end
      elsif(mail.to.include?(NOTIFY_ADDRESS))
        logger.info("=-=-=-=-=-= Processing expert bounce #{bounce.type}.")
        from_address = mail.from[0]
        # find account
        if(user = User.find_by_email(from_address))
          logger.info("=-=-=-=-=-= Found account match - Account ID #{user.id}.")
          if(assigned_questions = user.assigned_questions)
            logger.info("=-=-=-=-=-= Found #{assigned_questions.size} assigned questions.")
          else
            logger.info("=-=-=-=-=-= WARNING - found no assigned questions!")
          end
        else
          logger.info("=-=-=-=-=-= WARNING found no user match! - #{from_address}.")
        end
      end
    else
      logger.info("=-=-=-=-=-= Processing non-bounce email.")      
      if(mail.to.include?(PUBLIC_ADDRESS))
        logger.info("=-=-=-=-=-= Processing public mail.")
      elsif(mail.to.include?(NOTIFY_ADDRESS))
        logger.info("=-=-=-=-=-= Processing expert mail.")
      end
      from_address = mail.from[0]
      # find account
      if(account = Account.find_by_email(from_address))
        logger.info("=-=-=-=-=-= Found account match - Account ID #{account.id}.")
      end
    end
      
    creation_attributes = {:from => mail.from.join(','), :to => mail.to.join(','), :subject => mail.subject, :message_id => mail.message_id, :mail_date => mail.date, :bounced => bounce.is_bounce?}
    if(bounce.is_bounce?)
      creation_attributes.merge!({:bounce_code => bounce.code, :bounce_type => bounce.type, :bounce_reason => bounce.reason})
    end
    self.create(creation_attributes)
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
    
end
