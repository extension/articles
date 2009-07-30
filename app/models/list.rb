# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class List < ActiveRecord::Base
  
  SUBSCRIPTIONTYPES = {'subscribers' => 'Subscribed to the mailing list',
           'optout' => 'Opted out of mailing list subscription',
           'ineligible' => 'Ineligible for mailing list subscription',           
           'unconnected' => 'Subscribed to mailing list, not connected with the community',           
           'noidsubscribers' => 'Subscribed to the mailing list, does not have eXtensionID'}
           
  OWNERTYPES = {'moderators' => 'Mailing list moderators',
                'nonmoderators' => 'Not mailing list moderators',
                'idowners' => 'Owners',
                'noidowners' => 'Owns the mailing list, does not have eXtensionID'}         
           
  has_many :list_subscriptions, :dependent => :destroy
  has_many :list_owners, :dependent => :destroy
  has_many :users, :through => :list_subscriptions
  has_many :owners, :source => :user, :through => :list_owners
  
  has_many :list_posts
  
  has_many :communitylistconnections, :dependent => :destroy
  has_one    :community, :through => :communitylistconnections
  
  validates_length_of :name, :maximum=>50
  
    
  def recent_posts(limit = 10)
    self.list_posts.find(:all, :order => 'posted_at DESC', :limit => limit)  
  end

  def get_posting_stats(datecondition)
    messages = self.list_posts.bydate(datecondition).count
    senders = self.list_posts.bydate(datecondition).count(:all, :group => :senderemail).size
    totalsize = self.list_posts.bydate(datecondition).sum(:size)
    return {:messages => messages, :senders => senders, :totalsize => totalsize}
  end
  
  def get_count_bysender(datecondition,getsize = true)
    messagearray = self.list_posts.bydate(datecondition).count(:all, :group => :user_id, :order => "count_all DESC")
    if(getsize)
      sizearray =  self.list_posts.bydate(datecondition).sum(:size, :group => :user_id)
      sizehash = {}
      sizearray.map{|entry| sizehash[entry[0]] = entry[1]}
      returnarray = messagearray.map{|entry| [entry[0],entry[1],sizehash[entry[0]]]}
    else
      returnarray = messagearray
    end
    return returnarray
  end
  
  def get_count_bylist(datecondition,getsize = true)
    messagearray = self.list_posts.bydate(datecondition).count(:all, :group => :list_id, :order => "count_all DESC")
    if(getsize)
      sizearray =  self.list_posts.bydate(datecondition).sum(:size, :group => :list_id)
      sizehash = {}
      sizearray.map{|entry| sizehash[entry[0]] = entry[1]}
      returnarray = messagearray.map{|entry| [entry[0],entry[1],sizehash[entry[0]]]}
    else
      returnarray = messagearray
    end
    return returnarray
  end
    
  def is_announce_list?
    return (self.name == AppConfig.configtable['list-announce'])
  end
  
  def add_or_update_subscription(user)
    if self.users.include?(user)
      subscription = ListSubscription.find(:first, :conditions => {:list_id => self.id, :user_id => user.id})
      if(!subscription.nil?)
        optout = (self.is_announce_list?) ? !user.announcements? : subscription.optout
        ineligible = user.ineligible_for_listsubscription?
        subscription.update_attributes(:email => user.email, :emailconfirmed => user.emailconfirmed, :ineligible => ineligible, :optout => optout )
        AdminEvent.log_data_event(AdminEvent::UPDATE_SUBSCRIPTION, {:listname => self.name, :userlogin => user.login, :email => user.email, :emailconfirmed => user.emailconfirmed, :ineligible => ineligible, :optout => optout})
        return true
      else
        return false
      end
    else
      optout = (self.is_announce_list?) ? !user.announcements? : false
      ineligible = user.ineligible_for_listsubscription?
      subscription = ListSubscription.create(:list => self, :user => user, :email => user.email, :emailconfirmed => user.emailconfirmed, :ineligible => ineligible, :optout => optout)
      AdminEvent.log_data_event(AdminEvent::CREATE_SUBSCRIPTION, {:listname => self.name, :userlogin => user.login, :email => user.email, :emailconfirmed => user.emailconfirmed, :ineligible => ineligible, :optout => optout})
      return true
    end
  end

  def add_or_update_ownership(user)
    if self.owners.include?(user)
      ownership = ListOwner.find(:first, :conditions => {:list_id => self.id, :user_id => user.id})
      if(!ownership.nil?)
        ineligible = user.ineligible_for_listsubscription?
        ownership.update_attributes(:email => user.email, :emailconfirmed => user.emailconfirmed, :ineligible => ineligible)
        AdminEvent.log_data_event(AdminEvent::UPDATE_OWNERSHIP, {:listname => self.name, :userlogin => user.login, :email => user.email, :emailconfirmed => user.emailconfirmed, :ineligible => ineligible})
        return true
      else
        return false
      end
    else
      ineligible = user.ineligible_for_listsubscription?
      ownership = ListOwner.create(:list => self, :user => user, :email => user.email, :emailconfirmed => user.emailconfirmed, :ineligible => ineligible, :moderator => false)
      AdminEvent.log_data_event(AdminEvent::CREATE_OWNERSHIP, {:listname => self.name, :userlogin => user.login, :email => user.email, :emailconfirmed => user.emailconfirmed, :ineligible => ineligible, :moderator => false})
      return true
    end
  end  
  
  def remove_subscription(user_or_email)
    if(user_or_email.is_a?(User))
      subscriptionemail = user_or_email.email
    else # assume it's an email address string
      subscriptionemail = user_or_email
    end
    
    subscriptions = ListSubscription.find(:all, :conditions => {:list_id => self.id, :email => subscriptionemail})
    if(!subscriptions.empty?)
      ListSubscription.delete_all("id IN (#{subscriptions.map{|sub| "'#{sub.id}'"}.join(',')})")
      return true
    else
      return false
    end
  end
  
  def remove_ownership(user_or_email)
    if(user_or_email.is_a?(User))
      owneremail = user_or_email.email
    else # assume it's an email address string
      owneremail = user_or_email
    end
    
    ownerships = ListOwner.find(:all, :conditions => {:list_id => self.id, :email => owneremail})
    if(!ownerships.empty?)
      ListOwner.delete_all("id IN (#{ownerships.map{|ownership| "'#{ownership.id}'"}.join(',')})")
      return true
    else
      return false
    end
  end
  
  def remove_subscriptions(itemlist)
    itemlist.each do |user_or_email|
      # honestly, these all should be the same object, but I don't think there's much penalty to check
      self.remove_subscription(user_or_email)
    end
  end
  
  
      
  def update_subscriptions(userlist,checkmanaged = true)
    addcount = 0
    removecount = 0
    return {:adds => addcount, :removes => removecount} if(checkmanaged and !self.managed)
    
    if(!self.managed or !self.dropunconnected or !self.dropforeignsubscriptions)
      # make sure that subscriptions are associated
      self.associate_subscribers_to_people
    end
    

        
    currentusers = self.list_subscriptions.reject(&:notassociated?).map(&:user)
    currentpplemails = currentusers.map{|user| user.email.downcase}
    
    allcurrentemails = self.list_subscriptions.map{|listsub| listsub.email.downcase}
    
    userlistemails = userlist.map{|user| user.email.downcase}
    
    addusers = userlist - currentusers
    
    if(self.dropforeignsubscriptions and self.dropunconnected)
      removes = allcurrentemails - userlistemails
    elsif(self.dropunconnected)
      removes = currentpplemails - userlistemails
    elsif(self.dropforeignsubscriptions)
      removes = (allcurrentemails - currentpplemails) - userlistemails
      # shouldn't be any different than (allcurrentemails - currentpplemails) - but doesn't hurt
    else
      removes = []
    end
    
    
    
    # adds
    addusers.each do |adduser|
      addcount += 1
      optout = (self.is_announce_list?) ? !adduser.announcements? : false
      ineligible = adduser.ineligible_for_listsubscription?
      list_subscriptions.build(:list => self, :email => adduser.email, :user_id => adduser.id, :emailconfirmed => adduser.emailconfirmed, :ineligible => ineligible, :optout => optout)
    end
    
    # removes
    list_subscriptions.reject(&:new_record?).each do |listsub|
      removeit = removes.include?(listsub.email.downcase)
      if removeit
        removecount += 1
        list_subscriptions.delete(listsub)
      else
        if(!listsub.user.nil?)
          listsub.emailconfirmed = listsub.user.emailconfirmed?
          listsub.optout = (self.is_announce_list?) ? !listsub.user.announcements? : listsub.optout
          listsub.ineligible = listsub.user.ineligible_for_listsubscription?
        end
      end
    end
    
    # update
    list_subscriptions.each do |listsub|
      listsub.save(false)
    end 
  
    AdminEvent.log_data_event(AdminEvent::UPDATE_SUBSCRIPTIONS, {:listname => self.name, :adds => addcount, :removes => removecount})
    return {:adds => addcount, :removes => removecount}
  end
  
  def update_owners(userlist,checkmanaged = true,isrecursive=true)
    addcount = 0
    removecount = 0
    return {:adds => addcount, :removes => removecount} if(checkmanaged and !self.managed)
    
    if(!self.managed)
      # make sure that owners are associated
      self.associate_owners_to_people
    end
    
    currentowners = self.list_owners.reject(&:notassociated?).map(&:user)
    allcurrentowneremails = self.list_owners.map{|listowner| listowner.email.downcase}
    
    userlistemails = userlist.map{|user| user.email.downcase}
    
    addusers = userlist - currentowners
    removes = allcurrentowneremails - userlistemails
    
    # adds
    addusers.each do |adduser|
      addcount += 1
      list_owners.build(:list => self, :email => adduser.email, :user_id => adduser.id, :emailconfirmed => adduser.emailconfirmed, :ineligible => adduser.ineligible_for_listsubscription?, :moderator => false)
    end

    # removes
    list_owners.reject(&:new_record?).each do |listowner|
      removeit = (removes.include?(listowner.email.downcase) and listowner.email.downcase != AppConfig.configtable['default-list-owner'])
      if removeit
        removecount += 1
        list_owners.delete(listowner)
      else
        if(!listowner.user.nil?)
          listowner.emailconfirmed = listowner.user.emailconfirmed?
          listowner.ineligible = listowner.user.ineligible_for_listsubscription?
        end
      end
    end
    
    # add default-list-owner if not present
    if(!allcurrentowneremails.include?(AppConfig.configtable['default-list-owner']))
      addcount += 1
      list_owners.build(:list => self, :email => AppConfig.configtable['default-list-owner'], :user_id => 0, :emailconfirmed => true, :ineligible => false, :moderator => false)
    end
    
    # update
    list_owners.each do |listowner|
      listowner.save(false)
    end 
    
    AdminEvent.log_data_event(AdminEvent::UPDATE_OWNERS, {:listname => self.name, :adds => addcount, :removes => removecount})
    return {:adds => addcount, :removes => removecount}
    
  end
  
  def makemanaged(options = {})
    updateoptions = options.merge({:managed => true})
    self.update_attributes(updateoptions)
    self.associate_subscribers_to_people
    self.associate_owners_to_people
    return true
  end
  
  def people_subscriptions(options = {})
    ListSubscription.people_subscriptions([self.id],options)    
  end
  
  def connected_and_managed?
    return (!self.community.nil? and self.managed?)
  end
  
  def communityconnection
    if(self.community.nil?)
      nil
    else
      Communitylistconnection.find_by_list_id_and_community_id(self.id, self.community.id)
    end
  end
  
  def communityconnection_to_s(tolower=false)
    connection = self.communityconnection
    if(connection.nil?)
      return ''
    end
    
    returnlabel = connection.connectiontype
    
    if(tolower)
      returnlabel.downcase
    else
      returnlabel.capitalize
    end
  end    
  
  def get_subscription_for_user(user)
    ListSubscription.find_by_user_id_and_list_id(user.id,self.id)
  end
  
  def get_ownership_for_user(user)
    ListOwner.find_by_user_id_and_list_id(user.id,self.id)
  end
  
  def associate_subscribers_to_people
    ListSubscription.associate_people([self.id])
  end
  
  def associate_owners_to_people
    ListOwner.associate_people([self.id])
  end
  
  def connectedusers
    if(!self.managed?)
      return self.list_subscriptions.subscribers
    end
    
    if(self.dropunconnected)
      return []
    end
    
    connection = self.communityconnection
    if(connection.nil?)
      return self.list_subscriptions.subscribers
    end
    
    connectedusers = self.community.send(connection.connectiontype)
    return connectedusers
  end
  
  def unconnected_subscription_count
    self.list_subscriptions.filteredsubscribers(self.connectedusers,false).count
  end
  
  def is_unconnected_user?(user)
    connection = self.communityconnection
    if(connection.nil?)
      return true
    end
    
    connectedusers = self.community.send(connection.connectiontype)
    return !(connectedusers.include?(user))
    
  end
  
      
  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  class << self
        
    def per_page
      25
    end
    

    
    def inactive(datecondition)
      # if(datecondition.nil?)
      #      findopts = nil
      #    elsif(datecondition == 'today')
      #      findopts = {:conditions => 'DATE(lists.created_at) = CURDATE()'}
      #    elsif(datecondition == 'lastweek')
      #      findopts = {:conditions => 'lists.created_at < date_sub(curdate(), INTERVAL 1 WEEK)'}
      #    elsif(datecondition == 'lastmonth')
      #      findopts = {:conditions => 'lists.created_at < date_sub(curdate(), INTERVAL 1 MONTH)'}
      #    else
      #      findopts = nil
      #    end
      #    
      active_list_ids = ListPost.bydate(datecondition).count(:all, :group => :list_id).map{|item| item[0]}
      all_list_ids = List.find(:all).reject{|list| list.name == "mailman"}.map(&:id)
      inactive_ids = all_list_ids - active_list_ids
      return List.find(inactive_ids)
    end
        
    def find_by_name_or_id(searchterm)
      list = find_by_id(searchterm)
      if(list.nil?)
        list = find_by_name(searchterm)
      end
      return list
    end
    
    def find_or_createnewlist(listoptions)
      if(listoptions.nil? or listoptions[:name].nil?)
        return nil
      end
      
      makelistname = listoptions[:name].downcase
      list = List.find_by_name(makelistname)
      if(list.nil?)
        creationoptions = List.defaultoptions().merge(listoptions)
        # force the lowercase name
        creationoptions[:name] = makelistname
        list = List.create(creationoptions)
        # force default-list-owner into the list owners
        if(!list.nil?)  
          listsub = ListOwner.create(:list => list, :email => AppConfig.configtable['default-list-owner'], :emailconfirmed => true, :ineligible => false, :moderator => false)
          # log event
          ae = AdminEvent.log_data_event(AdminEvent::CREATE_LIST, creationoptions)
        end
      end
      return list
    end
    
    def defaultoptions
      return {:advertised => false, :managed => true, :dropforeignsubscriptions => true, :dropunconnected => true}
    end
    
    def find_announce_list
      List.find_by_name(AppConfig.configtable['list-announce'])
    end
      
        
  end

end
