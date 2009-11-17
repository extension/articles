# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class NumberSummary

  attr_accessor :internalfindoptions, :summarydateinterval, :forcecacheupdate, :filtercommunity
  #attr_reader :total,:new,:active,:applications,:locations,:positions,:agreements,:institutions,:communities, :communityconnection, :findoptions
  
  def initialize(options = {})
    ActiveRecord::Base.logger.debug(options.inspect)
    
    @data = {}
    @internalfindoptions = options[:findoptions].nil? ? {} : options[:findoptions]
    if(@internalfindoptions[:dateinterval].nil?)
      @internalfindoptions[:dateinterval] = 'all'
    end
    self.summarydateinterval = options[:summarydateinterval].nil? ? 'withinlastmonth' : options[:summarydateinterval] 
    self.forcecacheupdate = options[:forcecacheupdate].nil? ? false : options[:forcecacheupdate]  
    self.filtercommunity = options[:filtercommunity].nil? ? nil : options[:filtercommunity]
    if(!self.filtercommunity.nil?)
      @internalfindoptions.merge!(:community => self.filtercommunity)
      if(@internalfindoptions[:connectiontype].blank?)
        @internalfindoptions.merge!(:connectiontype => 'joined')
      end
    end
  end
  
  def findoptions
    # make sure to return a copy!
    Marshal::load(Marshal.dump(self.internalfindoptions))
  end
  
  def communityconnection(wants = ['leaders','members','wantstojoin','invited','interest'])
    if(self.filtercommunity.nil?)
      return nil
    end
    
    get_or_set_data_value(this_method.to_sym) do 
      returnhash = {}
      wants.each do |connectiontype|
        returnhash[connectiontype.to_sym] = self.filtercommunity.send(connectiontype).count
      end
      returnhash
    end
  end
    
  def totalpeople
    get_or_set_data_value(this_method.to_sym) do 
      User.filtered_count(self.findoptions,self.forcecacheupdate)
    end
  end
  
  def newpeople
    get_or_set_data_value(this_method.to_sym) do 
      Activity.count_signups(self.findoptions.merge({:dateinterval => self.summarydateinterval}),self.forcecacheupdate)
    end
  end
  
  def active
    get_or_set_data_value(this_method.to_sym) do 
      Activity.count_active_users(self.findoptions.merge({:dateinterval => self.summarydateinterval}),self.forcecacheupdate)
    end
  end
  
  def applications
    get_or_set_data_value(this_method.to_sym) do 
      countoptions = self.findoptions.merge({:dateinterval => self.summarydateinterval})
      if(!self.filtercommunity.nil?)
        countoptions.merge!(:connectiontype => 'joined')
      end
      Activity.count_users_contributions_objects_by_activityentrytype(countoptions,self.forcecacheupdate)
    end
  end
  
  def locations
    get_or_set_data_value(this_method.to_sym) do 
      Location.filtered(self.findoptions).count(:id, :distinct => true)
    end
  end
  
  def published_events
    get_or_set_data_value(this_method.to_sym) do 
      result = Activity.count_users_contributions_objects_by_activityentrytype(self.findoptions.merge({:activity=>"edit", :appname=>"events"}),self.forcecacheupdate)
      check_result_for_nil(result,'event',:objects)
    end
  end
  
  def published_copwikipages
    get_or_set_data_value(this_method.to_sym) do       
       result = Activity.count_users_contributions_objects_by_activityentrytype(self.findoptions.merge({:activity=>"publish", :appname=>"copwiki"}),self.forcecacheupdate)
       check_result_for_nil(result,'copwiki_page',:objects)
    end
  end
  
  def published_faqs
    get_or_set_data_value(this_method.to_sym) do 
       result = Activity.count_users_contributions_objects_by_activityentrytype(self.findoptions.merge({:activity=>"publish", :appname=>"faq"}),self.forcecacheupdate)
       check_result_for_nil(result,'faq',:objects)
    end
  end
  
  def resolved_questions
    get_or_set_data_value(this_method.to_sym) do 
      result = Activity.count_users_contributions_objects_by_activityentrytype(self.findoptions.merge({:activity=>"aaeresolve"}),self.forcecacheupdate)
      check_result_for_nil(result,'aae_question',:objects)
    end
  end
  
  def rejected_questions
    get_or_set_data_value(this_method.to_sym) do 
      result = Activity.count_users_contributions_objects_by_activityentrytype(self.findoptions.merge({:activity=>"aaereject"}),self.forcecacheupdate)
      check_result_for_nil(result,'aae_question',:objects)
    end
  end
  
  def unanswered_questions
    get_or_set_data_value(this_method.to_sym) do 
      result = Activity.count_users_contributions_objects_by_activityentrytype(self.findoptions.merge({:activity=>"aaenoanswer"}),self.forcecacheupdate)
      check_result_for_nil(result,'aae_question',:objects)
    end
  end
   
  def submitted_questions
    get_or_set_data_value(this_method.to_sym) do 
      result = Activity.count_users_contributions_objects_by_activityentrytype(self.findoptions.merge({:activity=>"aaesubmission"}),self.forcecacheupdate)
      check_result_for_nil(result,'aae_question',:objects)
    end
  end
  
  def counties
    get_or_set_data_value(this_method.to_sym) do 
      County.filtered(self.findoptions).count(:id, :distinct => true)
    end
  end
  
  def positions
    get_or_set_data_value(this_method.to_sym) do 
      Position.filtered(self.findoptions).count(:id, :distinct => true)
    end
  end
  
  def agreements(wants = ['empty','agree','reject'])
    get_or_set_data_value(this_method.to_sym) do 
      returnhash = {}
      wants.each do |agreementstatus|
        returnhash[agreementstatus.to_sym] =  User.filtered_count(self.findoptions.merge({:agreementstatus => agreementstatus}),self.forcecacheupdate)
      end
      returnhash
    end
  end
      
  def communities(wants = ['approved','usercontributed','institution'],wantconnections = ['joined'])
    get_or_set_data_value(this_method.to_sym) do   
      returnhash = {}
      wants.each do |communitytype|
        returnhash[communitytype.to_sym] = {}
        returnhash[communitytype.to_sym][:count] = Community.userfilter_count(self.findoptions.merge({:communitytype => communitytype})).size
        wantconnections.each do |connectiontype|
          returnhash[communitytype.to_sym][connectiontype.to_sym] = User.filtered_count(self.findoptions.merge({:connectiontype => connectiontype,:communitytype => communitytype}))
        end
      end
      returnhash
    end
  end
  
  private
  
  def check_result_for_nil(resulthash,typekey,valuekey)
   (resulthash[typekey].nil? or resulthash[typekey][valuekey].nil?) ? 0 : resulthash[typekey][valuekey]     
  end
    
  def get_or_set_data_value(key)
    if(!@data[key].blank?)
      @data[key]
    elsif block_given?
      @data[key] = yield
      @data[key]
    else
      nil
    end
  end
  
end