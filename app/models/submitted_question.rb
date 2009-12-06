# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'hpricot'

class SubmittedQuestion < ActiveRecord::Base

belongs_to :county
belongs_to :location
belongs_to :widget
has_many :submitted_question_events
has_and_belongs_to_many :categories
# TODO: need to change this
belongs_to :contributing_question, :class_name => "SearchQuestion", :foreign_key => "current_contributing_question"
belongs_to :assignee, :class_name => "User", :foreign_key => "user_id"
belongs_to :resolved_by, :class_name => "User", :foreign_key => "resolved_by"
belongs_to :public_user
has_many :responses


# currently, no need to cache, we don't fulltext search tags
# has_many :cached_tags, :as => :tagcacheable

validates_presence_of :asked_question
# check the format of the question submitter's email address
validates_format_of :zip_code, :with => %r{\d{5}(-\d{4})?}, :message => "should be like XXXXX or XXXXX-XXXX", :allow_blank => true, :allow_nil => true

before_create :generate_fingerprint, :clean_question_and_answer, :set_last_opened
before_update :clean_question_and_answer

after_save :assign_parent_categories
after_create :auto_assign_by_preference, :notify_submitter 



has_rakismet :author => proc { "#{self.submitter_firstname} #{self.submitter_lastname}" },
             :author_email => :submitter_email,
             :comment_type => "ask an expert question",
             :content => :asked_question,
             :permalink => proc { (self.external_app_id == 'widget') ? "#{AAEHOST}/widget" : "#{AAEHOST}/ask" },
             :user_ip => :user_ip,
             :user_agent => :user_agent,
             :referrer => :referrer
             
ordered_by :default => "#{self.table_name}.created_at ASC"
             
# status numbers (will be used from now on for status_state and the old field of status will be phased out)     
STATUS_SUBMITTED = 1
STATUS_RESOLVED = 2
STATUS_NO_ANSWER = 3
STATUS_REJECTED = 4

# status text (to be used when a text version of the status is needed)
SUBMITTED_TEXT = 'submitted'
RESOLVED_TEXT = 'resolved'
ANSWERED_TEXT = 'answered'
NO_ANSWER_TEXT = 'not_answered'
REJECTED_TEXT = 'rejected'

STATUS_TO_STR = {STATUS_SUBMITTED => SUBMITTED_TEXT, STATUS_RESOLVED => RESOLVED_TEXT, STATUS_NO_ANSWER => NO_ANSWER_TEXT, STATUS_REJECTED => REJECTED_TEXT}

EXPERT_DISCLAIMER = "This message for informational purposes only. " +  
                    "It is not intended to be a substitute for personalized professional advice. For specific local information, " + 
                    "contact your local county Cooperative Extension office or other qualified professionals." + 
                    "eXtension Foundation does not recommend or endorse any specific tests, professional, products, procedures, opinions, or other information " + 
                    "that may be mentioned. Reliance on any information provided by eXtension Foundation, employees, suppliers, member universities, or other " + 
                    "third parties through eXtension is solely at the user’s own risk. All eXtension content and communication is subject to  the terms of " + 
                    "use http://www.extension.org/main/termsofuse which may be revised at any time."
                    
PUBLIC_RESPONSE_REASSIGNMENT_COMMENT = "This question has been reassigned to you because a new comment has been posted to your response. Please " +
"reply using the link below or close the question out if no reply is needed. Thank You."
                    
DEFAULT_SUBMITTER_NAME = "External Submitter"

DECLINE_ANSWER = "Thank you for your question for eXtension. The topic area in which you've made a request is not yet fully staffed by eXtension experts and therefore we cannot provide you with a timely answer. Instead, if you live in the United States, please consider contacting the Cooperative Extension office closest to you. Simply go to http://www.extension.org, drop in your zip code and choose the local office in your neighborhood. We apologize for this inconvenience but please come back to eXtension to check in as we grow and add experts."

ALL_RESOLVED_STATII = [STATUS_RESOLVED, STATUS_REJECTED, STATUS_NO_ANSWER]

AAEHOST = "http://#{AppConfig.configtable['url_options']['host']}"

WRANGLER_REASSIGN_COMMENT = "This question has been assigned to you because the previous assignee clicked the 'Hand off to a Question Wrangler' button."

# scoping it out for various question states
named_scope :resolved, :conditions => "submitted_questions.status_state IN (#{ALL_RESOLVED_STATII.join(',')}) AND submitted_questions.spam = FALSE"
named_scope :answered, :conditions => "submitted_questions.status_state = #{STATUS_RESOLVED} AND submitted_questions.spam = FALSE"
named_scope :rejected, :conditions => "submitted_questions.status_state = #{STATUS_REJECTED} AND submitted_questions.spam = FALSE"
named_scope :not_answered, :conditions => "submitted_questions.status_state = #{STATUS_NO_ANSWER} AND submitted_questions.spam = FALSE" 
named_scope :submitted, :conditions => "submitted_questions.status_state = #{STATUS_SUBMITTED} AND submitted_questions.spam = FALSE"
named_scope :submittedspam, :conditions => "submitted_questions.status_state = #{STATUS_SUBMITTED} AND submitted_questions.spam = TRUE"


named_scope :listdisplayincludes, :include => [:categories, :assignee, :county, :location]

# filter scope by various conditions
named_scope :filtered, lambda {|options| filterconditions(options)}  
# both of these are expecting a "date expression" - not a date string
named_scope :resolved_since, lambda{|date_expression| {:conditions => "#{self.table_name}.resolved_at > #{date_expression}"}}
named_scope :created_since, lambda{|date_expression| {:conditions => "#{self.table_name}.created_at > #{date_expression}"}}

named_scope :escalated, lambda{|sincehours| {
  :conditions => "#{self.table_name}.last_opened_at < '#{(Time.now.utc - sincehours.hours).to_s(:db)}' AND #{self.table_name}.status_state = #{STATUS_SUBMITTED} AND #{self.table_name}.spam = FALSE"  
}}





# TODO: see if this should be converged with the :ordered named scope used through the pubsite controllers
named_scope :by_order, lambda { |*args| { :order => (args.first || 'submitted_questions.resolved_at desc') }}

#AAE Dashboard named scopes

#Response times named scopes for by_category report
named_scope :named_date_resp, lambda { |date1, date2| { :conditions => (date1 && date2) ?  [ " submitted_questions.created_at between ? and ? ", date1, date2] : " date_sub(curdate(), interval 90 day) <= submitted_questions.created_at" } }
named_scope :count_avgs_cat, lambda { |extstr| {:select => "category_id, avg(timestampdiff(hour, submitted_questions.created_at, resolved_at)) as ra", :joins => " join categories_submitted_questions on submitted_question_id=submitted_questions.id ",
         :conditions => [ " ( status_state=#{STATUS_RESOLVED} or status_state=#{STATUS_REJECTED} or status_state=#{STATUS_NO_ANSWER}) and external_app_id #{extstr} "], :group => " category_id" }  } 

#Response times named scopes for by_responder_locations report
 named_scope :count_avgs_loc, lambda { |extstr| {:select => "users.location_id, avg(timestampdiff(hour, submitted_questions.created_at, resolved_at)) as ra", :joins => " join users on submitted_questions.resolved_by=users.id ",
     :conditions => [ " ( status_state=#{STATUS_RESOLVED} or status_state=#{STATUS_REJECTED} or status_state=#{STATUS_NO_ANSWER}) and external_app_id #{extstr} "], :group => " users.location_id" }  } 
          
   
#activity named scopes
named_scope :date_subs, lambda { |date1, date2| { :conditions => (date1 && date2) ? [ "submitted_questions.created_at between ? and ?", date1, date2] : ""}}

# updates the submitted question, creates a response and  
# calls the function to log a new resolved submitted question event 
def add_resolution(sq_status, resolver, response, contributing_question = nil)
  
  t = Time.now
  
  case sq_status
    when STATUS_RESOLVED    
      self.update_attributes(:status => SubmittedQuestion.convert_to_string(sq_status), :status_state =>  sq_status, :resolved_by => resolver, :current_response => response, :resolver_email => resolver.email, :current_contributing_question => contributing_question, :resolved_at => t.strftime("%Y-%m-%dT%H:%M:%SZ"))  
      @response = Response.new(:resolver => resolver, :submitted_question => self, :response => response, :sent => true, :contributing_question_id => contributing_question)
      @response.save
      SubmittedQuestionEvent.log_resolution(self)    
    when STATUS_NO_ANSWER
      self.update_attributes(:status => SubmittedQuestion.convert_to_string(sq_status), :status_state =>  sq_status, :resolved_by => resolver, :current_response => response, :resolver_email => resolver.email, :current_contributing_question => contributing_question, :resolved_at => t.strftime("%Y-%m-%dT%H:%M:%SZ"))  
      @response = Response.new(:resolver => resolver, :submitted_question => self, :response => response, :sent => true, :contributing_question_id => contributing_question)
      @response.save
      SubmittedQuestionEvent.log_no_answer(self)  
    when STATUS_REJECTED
      self.update_attributes(:status => SubmittedQuestion.convert_to_string(sq_status), :status_state => sq_status, :current_response => response, :resolved_by => resolver, :resolver_email => resolver.email, :resolved_at => t.strftime("%Y-%m-%dT%H:%M:%SZ"), :show_publicly => false)
      SubmittedQuestionEvent.log_rejection(self)
  end
  
end

def set_last_opened
  self.last_opened_at = Time.now
end

def category_names
  if self.categories.length == 0
    return 'uncategorized'
  else
    if self.categories.length > 1 and subcat = self.categories.detect{|c| c.parent_id}
      return subcat.full_name
    else
      return self.categories[0].name 
    end
  end
end

def resolved?
  !self.status_state == STATUS_SUBMITTED
end

def assign_parent_categories
  categories.each do |category|
    if category.parent and !categories.include?(category.parent)
      categories << category.parent
    end
  end
end

def setup_categories(cat, subcat)
  if category = Category.find_by_id(cat)
    self.categories << category
  end
  
  if category and (subcategory = Category.find_by_id_and_parent_id(subcat, category.id))
    self.categories << subcategory
  end
end

def top_level_category
  return self.categories.detect{|c| c.parent_id == nil}
end

def sub_category
  top_level_cat = self.top_level_category
  if top_level_cat
    return self.categories.detect{|c| c.parent_id == top_level_cat.id}
  else
    return nil
  end
end

def has_response?
  sqe = self.submitted_question_events.find(:first, :conditions => {:event_state => SubmittedQuestionEvent::RESOLVED})
  if sqe
    return true
  else
    return false
  end
end

def all_public_responses
  pub_resp = self.asked_question
  if additional_responses = self.responses.find(:all, :conditions => "public_user_id IS NOT NULL") and additional_responses.length > 0
    pub_resp.concat('  (**response divider**)  ')
    pub_resp.concat(additional_responses.collect{|r| r.response}.join('  (**response divider**)  '))
  end
  
  return pub_resp
end

def all_expert_responses
  self.responses.find(:all, :conditions => "user_id IS NOT NULL").collect{|r| r.response}.join('  (**response divider**)  ')
end


 def self.find_earliest_record
   return self.find(:first, :order => 'created_at')
 end

  def self.find_questions(cat, desc, aux, locid, date1, date2, *args)
   tstring = ""; cdstring = ""
   case desc
      when "New"
        cdstring = "status_state=#{SubmittedQuestion::STATUS_SUBMITTED} and category_id=#{cat.id} "
        if locid
          cdstring = cdstring + " and locations.id = #{locid} "
         end
      when "Resolved"
          if aux
              cdstring = "status_state=#{aux} and "
          end
          cdstring= cdstring +  "resolved_by > 0 and category_id=#{cat.id}"
          if locid
            cdstring = cdstring + " and locations.id = #{locid}"
           end
      when "Resolver"
            if aux
              cdstring = " resolved_by = #{aux.to_i} and category_id=#{cat.id} and external_app_id IS NOT NULL "
            else
              cdstring= cdstring +  " resolved_by > 0 and category_id=#{cat.id} and external_app_id IS NOT NULL "
            end
     when "Answered as an Expert"
          cdstring = " sq.resolved_by = #{cat.id}"
     when "Assigned as an Expert"
          cdstring = " recipient_id= #{cat.id} "
   end
   if (date1 && date2)
     case desc
     when  "New", "Resolved", "Resolver", "Answered as an Expert", "Assigned as an Expert"
        tstring =" and sq.created_at between ? and  ?"
     end
     cdstring = [cdstring + tstring, date1, date2]
   end

   with_scope(:find => {:conditions => cdstring, :limit => ((desc == "Assigned as an Expert") ? nil : 100)}) do
       paginate(*args)
    end
  end
  
  def self.get_delineated_string(desc, cdstr)
      aux = desc
      if desc.length > 9
        case desc[9].chr
        when "a"
          cdstr = cdstr + " and status_state=#{SubmittedQuestion::STATUS_RESOLVED} "
        when "r"
           cdstr = cdstr + " and status_state=#{SubmittedQuestion::STATUS_REJECTED} "
        when "n"
           cdstr = cdstr + " and status_state=#{SubmittedQuestion::STATUS_NO_ANSWER} "
        end
        aux = desc[0..8]
      end
      [cdstr, aux]
   end
  
   def self.find_state_questions(loc, county, desc, date1, date2,  *args)
     rphrase = ""; tstring = ""; descaux = desc
     if (county)
       ctyid = County.find_by_sql(["Select id from counties where name=? and location_id=?", county, loc.id])
     end
     if (desc != "Submitted")
       cdstring =  " users.location_id='#{loc.id}'"
       if (county )
        cdstring = cdstring + "and users.county_id=#{ctyid[0].id}"
       end
     end
     case desc
      when "Submitted", "ResolvedP", "ResolvedPa", "ResolvedPr", "ResolvedPn"
        rphrase = " sq.location_id=#{loc.id}  "
        if (county)
          rphrase = rphrase + " and sq.county_id=#{ctyid[0].id}"
        end
        case desc
          when "Submitted"
             cdstring = " and sq.status_state=#{SubmittedQuestion::STATUS_SUBMITTED}"
          else
             cdstring = " and resolved_by > 0" 
             (cdstring, descaux) = get_delineated_string(desc, cdstring)
          end
      when "ResolvedM", "ResolvedMa", "ResolvedMr", "ResolvedMn"
         rphrase = " resolved_by > 0 and "
         (cdstring, descaux) = get_delineated_string(desc, cdstring)
      end     
     cdstring= rphrase + cdstring
     if (date1 && date2)
        case descaux
        when "Submitted", "ResolvedP", "ResolvedM"
           tstring = " and sq.created_at > ? and sq.created_at < ?"
        end
        cdstring =[cdstring + tstring, date1, date2]
     end
     with_scope(:find => { :conditions => cdstring , :limit => 100}) do
        paginate(*args)
     end
     
  end
  

#find the date that this submitted question was assigned to the current assignee
def assigned_date
  sqevent = self.submitted_question_events.find(:first, :conditions => "event_state = '#{SubmittedQuestionEvent::ASSIGNED_TO}'", :order => "created_at desc")
  #make sure that this event is valid by making sure that the user between the event and the submitted question match up
  if sqevent and (sqevent.recipient_id == self.user_id)
    return sqevent.created_at
  else
    return nil
  end
end

def clean_question_and_answer  
  if self.current_response and self.current_response.strip != ''
    self.current_response = Hpricot(self.current_response.sanitize).to_html 
  end
  
  self.asked_question = Hpricot(self.asked_question.sanitize).to_html
end

def submitter_fullname
  submitter_name = self.public_user.fullname if self.public_user
  if !submitter_name or submitter_name.strip == ''
    submitter_name = DEFAULT_SUBMITTER_NAME 
  end
  
  return submitter_name
end

# creates a notification to the submitter that we've received their question
def notify_submitter
  Notification.create(:notifytype => Notification::AAE_PUBLIC_SUBMISSION_ACKNOWLEDGEMENT, :user => User.systemuser, :additionaldata => {:submitted_question_id => self.id})
end

def auto_assign_by_preference
  if existing_sq = SubmittedQuestion.find(:first, :conditions => ["id != #{self.id} and asked_question = ? and submitter_email = '#{self.submitter_email}'", self.asked_question])
    reject_msg = "This question was a duplicate of incoming question ##{existing_sq.id}"
    self.add_resolution(STATUS_REJECTED, User.systemuser, reject_msg)
    return
  end
  
  if AppConfig.configtable['auto_assign_incoming_questions']
    auto_assign
  end
end

def auto_assign
  assignee = nil
  # first, check to see if it's from a named widget 
  # and route accordingly
  if widget = self.widget
    assignee = pick_user_from_list(widget.assignees)
  end
  
  if !assignee
    if !self.categories || self.categories.length == 0
      question_categories = nil
    else
      question_categories = self.categories
      parent_category = question_categories.detect{|c| !c.parent_id}
    end
  
    # if a state and county were provided when the question was asked
    # update: if there is location data supplied and there is not a category 
    # associated with the question, then route to the uncategorized question wranglers 
    # that chose that location or county in their location preferences
    if self.county and self.location
      assignee = pick_user_from_county(self.county, question_categories) 
    #if a state and no county were provided when the question was asked
    elsif self.location
      assignee = pick_user_from_state(self.location, question_categories)
    end
  end
  
  # if a user cannot be found yet...
  if !assignee
    if !question_categories
      # if no category, wrangle it
      assignee = pick_user_from_list(User.uncategorized_wrangler_routers)
    else
      # got category, first, look for a user with specified category
      assignee = pick_user_from_category(question_categories)
      # still ain't got no one? send to the wranglers to wrangle
      assignee = pick_user_from_list(User.uncategorized_wrangler_routers) if not assignee
    end  
  end
  
  if assignee
    systemuser = User.systemuser
    assign_to(assignee, systemuser, nil)
  else
    return
  end
end

# Assigns the question to the user, logs the assignment, and sends an email
# to the assignee letting them know that the question has been assigned to
# them.
def assign_to(user, assigned_by, comment, public_reopen = false, public_comment = nil)
  raise ArgumentError unless user and user.instance_of?(User)  
  
  # don't bother doing anything if this is assignment to the person already assigned unless it's 
  # a question that's been responded to by the public after it's been resolved that then gets 
  # assigned to whomever the question was last assigned to.
  return true if assignee and user.id == assignee.id and public_reopen == false
  
  if(!self.assignee.nil? and (assigned_by != self.assignee))
    is_reassign = true
    previously_assigned_to = self.assignee
  else
    is_reassign = false
  end
    
  # update and log
  update_attributes(:assignee => user)
  SubmittedQuestionEvent.log_event({:submitted_question => self,
                                    :recipient => user,
                                    :initiated_by => assigned_by,
                                    :event_state => SubmittedQuestionEvent::ASSIGNED_TO,
                                    :response => comment})
    
  # if this is a reopen reassignment due to the public user commenting on the sq                                  
  if public_comment
    asker_comment = public_comment.response
  else
    asker_comment = nil
  end
     
  # create notifications
  Notification.create(:notifytype => Notification::AAE_ASSIGNMENT, :user => user, :creator => assigned_by, :additionaldata => {:submitted_question_id => self.id, :comment => comment, :asker_comment => asker_comment})
  if(is_reassign and public_reopen == false)
    Notification.create(:notifytype => Notification::AAE_REASSIGNMENT, :user => previously_assigned_to, :creator => assigned_by, :additionaldata => {:submitted_question_id => self.id})
  end
end

# this is the method that gets invoked when someone wants to 
# give up their assigned question to a question wrangler.
def assign_to_question_wrangler(assigned_by)
  wranglers = User.uncategorized_wrangler_routers(self.location, self.county)
  assignee = pick_user_from_list(wranglers)
  
  comment = WRANGLER_REASSIGN_COMMENT

  assign_to(assignee, assigned_by, comment)
  return assignee
end



##Class Methods##

#finds submitted_questions for views like incoming questions and resolved questions

def self.filterconditions(options={})
  includes = []
  conditions = []
  
  if(options[:notrejected])
    conditions << "#{self.table_name}.status_state != #{SubmittedQuestion::STATUS_REJECTED}"
  end
  
  if(!options[:category].nil?)
    includes << :categories
    if options[:category] == Category::UNASSIGNED
      conditions << "categories.id IS NULL"
    else
      #look for the submitted questions of the category and all subcategories of the category
      if options[:category].children and options[:category].children.length > 0
        subcat_ids = options[:category].children.map{|sc| sc.id}.join(',')
        cat_ids = subcat_ids + ",#{options[:category].id}"
        conditions << "categories.id IN (#{cat_ids})"        
      else
        conditions << "categories.id = #{options[:category].id}"
      end
    end
  end
  
  if(!options[:resolved_by].nil?)
    conditions << "#{self.table_name}.resolved_by = #{options[:resolved_by].id}"
  end
  
  if(!options[:assignee].nil?)  
    conditions << "#{self.table_name}.user_id = #{options[:assignee].id}"
  end
 
  if(!options[:location].nil?)   
    conditions << "#{self.table_name}.location_id = #{options[:location].id}"
  end

  if(!options[:county].nil?)  
    conditions << "#{self.table_name}.county_id = #{options[:county].id}"
  end
  
  if(!options[:source].nil?)    
    case options[:source]
    when 'pubsite'
      conditions << "#{self.table_name}.external_app_id != 'widget'"
    when 'widget'
      conditions << "#{self.table_name}.external_app_id = 'widget'"
    else
      source_int = options[:source].to_i
      if source_int != 0
        if(widget = Widget.find(:first, :conditions => "id = #{source_int}"))
          conditions << "#{self.table_name}.widget_name = '#{widget.name}'"
        end
      end
    end
  end

  # is this part of a named_scope with another model? if so, the includes have to be nested
  # this happens when this is tacked on to a named_scope with the SubmittedQuestionEvents
  if(options[:is_subfilter])
    return {:include => {:submitted_question => includes.compact}, :conditions => conditions.compact.join(' AND ')}
  else
    return {:include => includes.compact, :conditions => conditions.compact.join(' AND ')}
  end
end

def self.find_uncategorized(*args)
  with_scope(:find => { :conditions => "categories.id IS NULL", :include => :categories }) do
    find(*args)
  end
end

# utility function to convert status_state numbers to status strings
def self.convert_to_string(status_number)
  case status_number
  when STATUS_SUBMITTED
    return 'submitted'
  when STATUS_RESOLVED
    return 'resolved'
  when STATUS_NO_ANSWER
    return 'no answer'
  when STATUS_REJECTED
    return 'rejected'
  else
    return nil
  end
end

def self.find_with_category(category, *args)
  with_scope(:find => { :conditions => "category_id = #{category.id} or categories.parent_id = #{category.id}", :include => :categories }) do
    find(*args)
  end
end



def SubmittedQuestion.get_extapp_qual( pub, wgt)
   extstr = " IS NOT NULL "
   if (pub && !wgt)
     extstr = " = 'www.extension.org'"
   end
   if (wgt && !pub)
     extstr = " = 'widget'"
   end   
   if (!pub && !wgt)
     extstr = " IS NULL"
   end
   return extstr
 end

def SubmittedQuestion.find_externally_submitted(date1, date2, pub, wgt)
   extstr = get_extapp_qual(pub, wgt)
   if extstr == " IS NULL";  return 0; end
   if (date1 && date2)
     return self.count(:all,
      :conditions => ["status_state=#{STATUS_SUBMITTED} and external_app_id #{extstr} and created_at >= ? and created_at <= ?", date1, date2])
   else
     return self.count(:all,
     :conditions => "status_state=#{STATUS_SUBMITTED} and external_app_id #{extstr}")
   end
 end
 
 def SubmittedQuestion.find_once_externally_submitted(date1, date2, pub, wgt)
    extstr = get_extapp_qual(pub, wgt)
     if extstr == " IS NULL";  return 0; end
     if (date1 && date2)
       return self.count(:all,
        :conditions => [" (status_state > 0 ) and external_app_id #{extstr} and created_at between ? and ?", date1, date2])
     else
       return self.count(:all,
       :conditions => " ( status_state > 0 ) and external_app_id #{extstr}")
     end
 end
 
 def SubmittedQuestion.get_avg_response_time(date1, date2, pub, wgt)
    extstr = get_extapp_qual(pub, wgt) 
    if extstr == " IS NULL"; return 0; end
    where_clause = " (status_state=#{STATUS_RESOLVED} or status_state=#{STATUS_REJECTED} or status_state=#{STATUS_NO_ANSWER} ) and external_app_id #{extstr}"
    if (date1 && date2)
      where_clause = [where_clause + " and created_at >= ? and created_at <= ?", date1, date2]
    end
    avg_time_in_hours = find(:all, :select => " avg(timestampdiff(hour, created_at, resolved_at)) as ra",   :conditions => where_clause)
    avg_time_in_hours[0].ra.to_i
  end
  
  def SubmittedQuestion.get_avg_open_time(date1, date2, dateTo, pub, wgt)
     extstr = get_extapp_qual(pub, wgt)
     if extstr == " IS NULL";  return 0; end
     where_clause = " status_state=#{STATUS_SUBMITTED} and external_app_id #{extstr}" 
     select_clause = " avg(timestampdiff(hour, created_at, now())) as cw "
     if (date1 && date2)
       where_clause = ["( status_state=#{STATUS_SUBMITTED} || ((status_state=#{STATUS_RESOLVED} or status_state=#{STATUS_REJECTED} or status_state=#{STATUS_NO_ANSWER}) and resolved_at >= ? and resolved_at <= ?)) and external_app_id #{extstr} and created_at >= ? and created_at <= ?", date1, date2, date1, date2]
       select_clause = " avg(timestampdiff(hour, created_at, '#{dateTo}')) as cw"
     end
     avg_open_times = find(:all, :select => select_clause, :conditions => where_clause)
     avg_open_times[0].cw.to_i
  end   
    
  def SubmittedQuestion.get_assignees(date1, date2, sqfilters, sqinclude)
     #if sqinclude, cannot do a select with include, so must do this workaround
       joinclause= [:assignee] 
      if (sqinclude && sqinclude[0]=="categories".to_sym)
        joinclause = " join users on users.id=submitted_questions.user_id join " +
                       "categories_submitted_questions on categories_submitted_questions.submitted_question_id=submitted_questions.id join categories " +
                       " on categories.id=categories_submitted_questions.category_id "                  
      end
      cond = " submitted_questions.status_state = #{STATUS_SUBMITTED} AND submitted_questions.spam = FALSE" + ((sqfilters and sqfilters!="" ) ? " and " + sqfilters : "")
       if (date1 && date2)
           cond = cond + " and submitted_questions.created_at between ? and ? "
       end
       SubmittedQuestion.find(:all, :select => "submitted_questions.created_at sqcreated_at, submitted_questions.id id, last_assigned_at, users.id uid, last_login_at, user_id, last_name, first_name, login", :joins => joinclause,
          :conditions => ((date1 && date2) ? [cond , date1, date2] : cond), :order => "submitted_questions.created_at DESC")               
  end
    
    
    
  def SubmittedQuestion.get_noq(date1, date2, extstr)
    noqr =SubmittedQuestion.named_date_resp(date1, date2).count(:joins =>  "join users on resolved_by=users.id ", :conditions => "external_app_id #{extstr}", :group => " users.location_id") 
    noqu = SubmittedQuestion.named_date_resp(date1, date2).count(:joins =>  "join users on submitted_questions.user_id=users.id ", :conditions => "external_app_id #{extstr}", :group => " users.location_id")
    noq = self.add_vals(noqr, noqu, '+')
    noq
  end

    
  def self.add_vals(noqr, noqu, oper)
    # merge and add the resolved and the assigned counts
    maxlen = [noqr.size, noqu.size].max { |a, b| a <=> b}; n1 = noqr.size
    if n1==maxlen; lrg = noqr; sml = noqu; else; lrg=noqu; sml = noqr; end
    noq = {}
    lrg.each do |id, val|
       if sml[id]
         if oper=='+'
           noq[id]= val + sml[id]
         else
           if n1==maxlen    # '-' = order dependent, first hash given value - second
             noq[id] = val - sml[id]
           else
             noq[id] = sml[id] - val
           end
         end
       else
         noq[id]= val
       end
    end
    sml.each do |id, val|
      if !lrg[id]
        noq[id] = val
      end
    end
    noq
  end
 
  
  def SubmittedQuestion.get_avg_response_time_past30(date1, date2, pub, wgt, nodays)
    extstr = get_extapp_qual(pub, wgt)
    if extstr == " IS NULL";  return 0; end
    where_clause = " date_sub(curdate(),interval #{nodays} day) <= resolved_at and (status_state=#{STATUS_RESOLVED} || status_state=#{STATUS_REJECTED} || status_state=#{STATUS_NO_ANSWER}) and external_app_id #{extstr}"
    if (date1 && date2)
      where_clause = [" date_sub(?, interval #{nodays} day) <= resolved_at and (status_state=#{STATUS_RESOLVED} || status_state=#{STATUS_REJECTED} || status_state=#{STATUS_NO_ANSWER}) and external_app_id #{extstr} and created_at >= ? and created_at <= ?", date2, date1, date2]
    end
    avg_time_in_hours=find(:all, :select => "avg(timestampdiff(hour, created_at, resolved_at)) as ra", :conditions => where_clause) 
    avg_time_in_hours[0].ra.to_i
  end
  
  #use a bit of reflection to
   # make hashes forthe different types...state, category, university
   def self.makehash(sqlarray, objfield, scale)
     h = Hash.new
     x = 0; lim = sqlarray.length
     while x < lim
         h[sqlarray[x].send(objfield.intern)]=(sqlarray[x].ra.to_f)/scale  
         x = x + 1
     end
     h
   end
     
      def SubmittedQuestion.get_answered_question_by_state_persp(bywhat, stateobj, date1, date2)
           statuses = ["", " and status_state=#{STATUS_RESOLVED}", " and status_state=#{STATUS_REJECTED}", " and status_state=#{STATUS_NO_ANSWER}"]
            results = Array.new; i = 0; cond_string = " and submitted_questions.created_at between ? and ?" ;  n = statuses.size
            if (bywhat == "member")
              bywhatstr = " users.location_id='#{stateobj.id}' "
            else
              bywhatstr = " location_id=#{stateobj.id} "
            end
            while i < n do
              cond = " resolved_by >=1 and " + bywhatstr + statuses[i]
              if (date1 && date2)
                cond = cond +  cond_string   
              end 
              results[i] = SubmittedQuestion.count(:all,  :joins => ((bywhat=="member") ? [:resolved_by] : nil),
                :conditions => ((date1 && date2) ? [cond, date1, date2] : cond))
              i = i + 1
            end  
            return [results[0], results[1], results[2], results[3]]
       end
    
    
     def SubmittedQuestion.get_answered_question_by_county_persp(bywhat, countyobj, date1, date2)
          statuses = ["", " and status_state=#{STATUS_RESOLVED}", " and status_state=#{STATUS_REJECTED}", " and status_state=#{STATUS_NO_ANSWER}"]
           results = Array.new; i = 0; cond_string = " and submitted_questions.created_at between ? and ?" ; n = statuses.size
           if (bywhat == "member")
             bywhatstr = " users.location_id=#{countyobj.location_id} and users.county_id=#{countyobj.id} "
           else
             bywhatstr = " county_id=#{countyobj.id} "
           end
           while i < n do
             cond = " resolved_by >=1 and " + bywhatstr + statuses[i]
             if (date1 && date2)
               cond = cond +  cond_string   
             end 
             results[i] = SubmittedQuestion.count(:all, :joins => ((bywhat=="member") ? [:resolved_by] : nil),:conditions => ((date1 && date2) ? [cond, date1, date2] : cond))
             i = i + 1
           end  
           return [results[0], results[1], results[2], results[3]]
      end


private

def generate_fingerprint
  create_time = Time.now.to_s
  appname = self.external_app_id ? self.external_app_id : 'unknown'
  self.question_fingerprint = Digest::MD5.hexdigest(appname + create_time + self.asked_question + self.submitter_email + AppConfig.configtable['sessionsecret'])
end

def pick_user_from_list(users)
  if !users or users.length == 0
    return nil
  end
  
  users.sort! { |a, b| a.assigned_questions.count(:conditions => "status_state = #{STATUS_SUBMITTED}") <=> b.assigned_questions.count(:conditions => "status_state = #{STATUS_SUBMITTED}")}

  questions_floor = users[0].assigned_questions.count(:conditions => "status_state = #{STATUS_SUBMITTED}")

  possible_users = users.select { |u| u.assigned_questions.count(:conditions => "status_state = #{STATUS_SUBMITTED}") == questions_floor }
  
  return nil if !possible_users or possible_users.length == 0

  return possible_users[0] if possible_users.length == 1

  assignment_dates = Hash.new
  
  possible_users.each do |u|
    question = u.assigned_questions.find(:first, :conditions => ["event_state = ?", SubmittedQuestionEvent::ASSIGNED_TO], :include => :submitted_question_events, :order => "submitted_question_events.created_at desc")

    if question
      assignment_dates[u.id] = question.submitted_question_events[0].created_at
    else
      assignment_dates[u.id] = Time.at(0)
    end
  end

  user_id = assignment_dates.sort{ |a, b| a[1] <=> b[1] }[0][0]

  return User.find(user_id)
end

def pick_user_from_county(county, question_categories)
  # if a county was selected for this question and there are users for this county
  county = ExpertiseCounty.find_by_fipsid(county.fipsid)
  county_users = User.narrow_by_routers(county.users, Role::AUTO_ROUTE)
  if county_users and county_users.length > 0
    # if there were categories
    if question_categories
      if subcat = question_categories.detect{|c| c.parent_id} 
        cat_county_users = subcat.get_user_intersection(county_users)
        # if there are no common users that have the subcat and county, then try the location and subcat intersection
        if !cat_county_users or cat_county_users.length == 0
          loc_subcat_user = pick_user_from_state(county.expertise_location, question_categories)
          # if there was no county, subcat intersection or location, subcat intersection, then use the subcat's users
          if loc_subcat_user  
            return loc_subcat_user 
          else
            cat_county_users = User.narrow_by_routers(subcat.users, Role::AUTO_ROUTE, true)
          end
        end  
      end
      # if no subcats, but top levels cats are associated with this question
      if (!cat_county_users or cat_county_users.length == 0) and (top_level_cat = question_categories.detect{|c| !c.parent_id})
        cat_county_users = top_level_cat.get_user_intersection(county_users)
        # if there are no common users between the top level category's users and the counties' users, then try the top level cat and location intersection
        if !cat_county_users or cat_county_users.length == 0
          loc_cat_user = pick_user_from_state(county.expertise_location, question_categories)
          if loc_cat_user 
            return loc_cat_user
          else
            cat_county_users = User.narrow_by_routers(top_level_cat.users, Role::AUTO_ROUTE, true)
          end
        end
      end 

    end # end of 'were there categories'

    # if there is no category or no users for the category, then get 
    # the intersection of the uncat. quest. wranglers and the users for this county
    if !cat_county_users or cat_county_users.length == 0
      uncat_county_users = User.uncategorized_wrangler_routers(county.expertise_location, county)
      # if there are no uncat. quest. wranglers with the preference set for this county, then route by location with no category
      if !uncat_county_users or uncat_county_users.length == 0
        return pick_user_from_state(county.expertise_location, nil)
      else
        return pick_user_from_list(uncat_county_users)
      end
    # if there were users for a category or users for a category that had that county preference set
    else
      return pick_user_from_list(cat_county_users)
    end
  # there were no users for this county  
  else
    return pick_user_from_state(county.expertise_location, question_categories)
  end # end of 'are there county users'
end

def pick_user_from_state(location, question_categories)
  location = ExpertiseLocation.find_by_fipsid(location.fipsid)
  all_county_loc = location.expertise_counties.find(:first, :conditions => "countycode = '0'")
  all_county_loc ? all_county_users = User.narrow_by_routers(all_county_loc.users, Role::AUTO_ROUTE) : all_county_users = nil
  
  #if a location was selected for this question and there are users for this location
  if all_county_users and all_county_users.length > 0
    
    #if a category was selected for this question
    if question_categories
      if subcat = question_categories.detect{|c| c.parent_id}
        cat_location_users = subcat.get_user_intersection(all_county_users)
        #if there were no common users between the location's users and the subcat's users, then use the subcat's users
        if !cat_location_users or cat_location_users.length == 0
          cat_location_users = User.narrow_by_routers(subcat.users, Role::AUTO_ROUTE, true)
        end
      end
      
      #if there was a top level category associated with the question and the top level category had users associated with it
      if (!cat_location_users or cat_location_users.length == 0) and (top_level_cat = question_categories.detect{|c| !c.parent_id})  
        cat_location_users = top_level_cat.get_user_intersection(all_county_users)
        #if there were no common users between the top level category's users and the location's users, then use the top level category's users
        if !cat_location_users or cat_location_users.length == 0
          cat_location_users = User.narrow_by_routers(top_level_cat.users, Role::AUTO_ROUTE, true)
        end
      end
      
    end # end of 'does it have categories'

    # if there is no category or no users for the category, then find the 
    # uncategorized question wranglers with this location preference set
    if !cat_location_users or cat_location_users.length == 0
      uncat_location_users = User.uncategorized_wrangler_routers(location, all_county_loc)
      # if there are no common users amongst uncat. quest. wranglers and location users
      if !uncat_location_users or uncat_location_users.length == 0
        return nil
      else
        return pick_user_from_list(uncat_location_users)
      end
    # if there were users found above for a category or combination of category and location
    else
      return pick_user_from_list(cat_location_users)
    end 
  end # end of 'does the location have users'

  # if there were no users that had the all state preference set
  return nil
end

def pick_user_from_category(question_categories)
  assignee = nil
  #look for subcategory first and make sure subcat has users
  if subcat = question_categories.detect{|c| c.parent_id } and subcat_users = subcat.users and subcat_users.length > 0
    assignee = pick_user_from_list(User.narrow_by_routers(subcat_users, Role::AUTO_ROUTE, true))
  end
  #if no subcat, then find the top_level category and make sure it has users
  if !assignee
    if top_level_cat = question_categories.detect{|c| !c.parent_id} and top_level_cat_users = top_level_cat.users and top_level_cat_users.length > 0
      assignee = pick_user_from_list(User.narrow_by_routers(top_level_cat_users, Role::AUTO_ROUTE, true))
    end
  end
  
  assignee
end

end



