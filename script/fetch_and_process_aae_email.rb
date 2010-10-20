#!/usr/bin/env ruby
require 'getoptlong'

### Program Options
progopts = GetoptLong.new(
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--skip-fetch","-s", GetoptLong::NO_ARGUMENT ]
  
)

@environment = 'production'
@skip_fetch = false
progopts.each do |option, arg|
  case option
    when '--environment'
      @environment = arg
    when '--skip-fetch'
      @skip_fetch = true
    else
      puts "Unrecognized option #{opt}"
      exit 0
    end
end
### END Program Options

if !ENV["RAILS_ENV"] || ENV["RAILS_ENV"] == ""
  ENV["RAILS_ENV"] = @environment
end

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")


def handle_vacations 
  vacation_emails = AaeEmail.unhandled.vacations
  if(!vacation_emails.blank?)
    vacation_emails.each do |aae_email|
      if(aae_email.destination == AaeEmail::PUBLIC)
        # ignore it
        aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::IGNORED)
      elsif(aae_email.destination == AaeEmail::ESCALATION)
        # ignore it
        aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::IGNORED)
      elsif(aae_email.destination == AaeEmail::EXPERT)
        case aae_email.reply_type
        when (AaeEmail::ASSIGN_REPLY or AaeEmail::OTHER_REPLY)
          # notify the previous assignee.  If previous assignee was system, reassign to a question wrangler
          if(!aae_email.submitted_question)
            # no question! - notify the hall monitors
            aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::FAILURE)
          elsif(!aae_email.account.blank?)
            # get previous assignee 
            if(latest_events = aae_email.submitted_question.submitted_question_events.latest_handling)
              event = latest_events[0]
              if(event.event_state == SubmittedQuestionEvent::ASSIGNED_TO)
                if(event.initiated_by and event.initiated_by != event.recipient and event.recipient == aae_email.account)
                  if(event.initiated_by == User.systemuser)
                    # reassign to a wrangler
                    if(aae_email.account)
                      aae_email.submitted_question.log_comment(aae_email.account, aae_email.plain_text_message)
                    end
                    comment = "Detected a vacation response on question assignment. Reassigning to a question wrangler."
                    aae_email.submitted_question.log_comment(User.systemuser, comment)
                    aae_email.submitted_question.assign_to_question_wrangler(User.systemuser)
                    aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::REASSIGN)
                  else
                    # comment and notify person that made the assignment
                    if(aae_email.account)
                      aae_email.submitted_question.log_comment(aae_email.account, aae_email.plain_text_message)
                    end
                    comment = "Detected a vacation response on question assignment. Sending a notification."
                    aae_email.submitted_question.log_comment(User.systemuser, comment)
                    aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::COMMENTED)
                    Notification.create(:notifytype => Notification::AAE_VACATION_RESPONSE, :user => event.initiated_by, :additionaldata => {:aae_email_id => aae_email.id})
                  end
                else
                  # self-assigned, ignore and notify hall monitors
                  aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::IGNORED)
                end
              else 
                # latest event not assignment, ignore and notify hall monitors
                aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::IGNORED)
              end  
            else 
              # no latest handling event, ignore and notify hall monitors
              aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::IGNORED)
            end
          end              
        else
          # all other replies - ignore it
          aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::IGNORED)
        end
      end
    end # each email
  end # empty list
end


def handle_bounces
  bounce_emails = AaeEmail.unhandled.bounces
  if(!bounce_emails.blank?)
    bounce_emails.each do |aae_email|
      if(aae_email.destination == AaeEmail::PUBLIC)
        if(!aae_email.submitted_question.blank?)
          # reject if not retryable, comment if it was retryable
          if(aae_email.retryable?)
            comment = "Detected a temporary automatic bounce response from the public. Will retry."
            aae_email.submitted_question.log_comment(User.systemuser, comment)
            aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::COMMENTED)
          else
            comment = "Detected a email bounce from the public email address. Automatically rejecting question, the public email will never receive it."
            aae_email.submitted_question.add_resolution(SubmittedQuestion::STATUS_REJECTED, User.systemuser, comment)
            if(aae_email.submitted_question.assignee)
              Notification.create(:notifytype => Notification::AAE_REJECT, :user => aae_email.submitted_question.assignee, 
                                  :creator => User.systemuser, :additionaldata => {:submitted_question_id => @submitted_question.id, :reject_message => comment})
            end
            aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::REJECTED)
          end
        else
          # no question! - notify the hall monitors
          aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::FAILURE)
        end
      elsif(aae_email.destination == AaeEmail::ESCALATION)
        # ignore it
        aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::IGNORED)
      elsif(aae_email.destination == AaeEmail::EXPERT)
        case aae_email.reply_type
        when (AaeEmail::ASSIGN_REPLY or AaeEmail::OTHER_REPLY)
          # notify the previous assignee.  If previous assignee was system, reassign to a question wrangler
          if(!aae_email.submitted_question)
            # no question! - notify the hall monitors
            aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::FAILURE)
          elsif(!aae_email.account.blank?)
            # get previous assignee 
            if(latest_events = aae_email.submitted_question.submitted_question_events.latest_handling)
              event = latest_events[0]
              if(event.event_state == SubmittedQuestionEvent::ASSIGNED_TO)
                if(event.initiated_by and event.initiated_by != event.recipient and event.recipient == aae_email.account)
                  if(event.initiated_by == User.systemuser)
                    # reassign to a wrangler - even if retryable
                    if(aae_email.account)
                      aae_email.submitted_question.log_comment(aae_email.account, aae_email.plain_text_message)
                    end
                    comment = "Detected a bounce response on question assignment. Reassigning to a question wrangler."
                    aae_email.submitted_question.log_comment(User.systemuser, comment)
                    aae_email.submitted_question.assign_to_question_wrangler(User.systemuser)
                    aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::REASSIGN)
                  else
                    # retryable? comment and notify person that made the assignment
                    if(aae_email.retryable?)
                      if(aae_email.account)
                        aae_email.submitted_question.log_comment(aae_email.account, aae_email.plain_text_message)
                      end
                      comment = "Detected a temporary bounce response on question assignment. Sending a notification."
                      aae_email.submitted_question.log_comment(User.systemuser, comment)
                      aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::COMMENTED)
                      Notification.create(:notifytype => Notification::AAE_VACATION_RESPONSE, :user => event.initiated_by, :additionaldata => {:aae_email_id => aae_email.id})
                    else
                      # assign to question wrangler, that's easier
                      if(aae_email.account)
                        aae_email.submitted_question.log_comment(aae_email.account, aae_email.plain_text_message)
                      end
                      comment = "Detected a bounce response on question assignment. Reassigning to a question wrangler."
                      aae_email.submitted_question.log_comment(User.systemuser, comment)
                      aae_email.submitted_question.assign_to_question_wrangler(User.systemuser)
                      aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::REASSIGN)
                    end
                  end
                else
                  # self-assigned, ignore and notify hall monitors
                  aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::IGNORED)
                end
              else 
                # latest event not assignment, ignore and notify hall monitors
                aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::IGNORED)
              end  
            else 
              # no latest handling event, ignore and notify hall monitors
              aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::IGNORED)
            end
          end              
        else
          # all other replies - ignore it
          aae_email.update_attributes(:action_taken_at => Time.now.utc, :action_taken => AaeEmail::IGNORED)
        end
      end
    end # each email
  end # empty list
end

begin
  Lockfile.new('/tmp/cron_mail_fetcher.lock', :retries => 0) do
    if(!@skip_fetch)
      AaeEmail.fetch_email
    end
    handle_vacations
    handle_bounces
  end
rescue Lockfile::MaxTriesLockError => e
  puts "Another fetcher is already running. Exiting."
end