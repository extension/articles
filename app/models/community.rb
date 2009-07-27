# === COPYRIGHT:
#  Copyright (c) 2005-2008 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
require 'hpricot'

class Community < ActiveRecord::Base
  serialize :cached_content_tag_data
  extend ConditionExtensions
  has_content_tags
  ordered_by :default => "#{self.table_name}.name ASC"

  UNKNOWN = 0
  
  # types
  APPROVED = 1
  USERCONTRIBUTED = 2
  EMERGING = 3
  SYSTEM = 4
  INSTITUTIONALTEAM = 5
  
  ENTRYTYPES = {APPROVED => {:label => 'eXtension Community of Practice', :allowadmincreate => true},
           USERCONTRIBUTED => {:label => 'User created community', :allowadmincreate => true},
           EMERGING => {:label => 'Emerging Community of Practice', :allowadmincreate => false},
           INSTITUTIONALTEAM => {:label => 'Institutional Team', :allowadmincreate => true},
           SYSTEM => {:label => 'System managed community', :allowadmincreate => false}}
           
  # membership
  OPEN = 1
  MODERATED = 2
  INVITATIONONLY = 3
  
  MEMBERFILTERS = {OPEN => 'Open Membership',
    MODERATED => 'Moderated Membership',
    INVITATIONONLY => 'Invitation Only Membership'}
  
           
  CONNECTIONS = {'member' => 'Community Member',
    'leader' => 'Community Leader',
    'wantstojoin' => 'Wants to Join Community',
    'interest' => 'Interested in Community',
    'invited' => 'Community Invitation'}

  has_many :communityconnections, :dependent => :destroy

  has_many :users, :through => :communityconnections
  has_many :validusers, :through => :communityconnections, :source => :user, :conditions => "users.retired = 0 and users.vouched = 1"
  has_many :wantstojoin, :through => :communityconnections, :source => :user, :conditions => "communityconnections.connectiontype = 'wantstojoin' and users.retired = 0 and users.vouched = 1"
  has_many :joined, :through => :communityconnections, :source => :user, :conditions => "(communityconnections.connectiontype = 'member' OR communityconnections.connectiontype = 'leader') and users.retired = 0 and users.vouched = 1"
  has_many :members, :through => :communityconnections, :source => :user, :conditions => "communityconnections.connectiontype = 'member' and users.retired = 0 and users.vouched = 1"
  has_many :leaders, :through => :communityconnections, :source => :user, :conditions => "communityconnections.connectiontype = 'leader' and users.retired = 0 and users.vouched = 1"
  has_many :invited, :through => :communityconnections, :source => :user, :conditions => "communityconnections.connectiontype = 'invited' and users.retired = 0 and users.vouched = 1"
  has_many :interest, :through => :communityconnections, :source => :user, :conditions => "communityconnections.connectiontype = 'interest' and users.retired = 0 and users.vouched = 1"
  has_many :nointerest, :through => :communityconnections, :source => :user, :conditions => "communityconnections.connectiontype = 'nointerest' and users.retired = 0 and users.vouched = 1"
  
  has_many :interested, :through => :communityconnections, :source => :user, :conditions => "communityconnections.connectiontype IN ('interest','wantstojoin','leader') and users.retired = 0 and users.vouched = 1"


  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  has_many :notifyleaders, :through => :communityconnections, :source => :user, :conditions => "communityconnections.connectiontype = 'leader' AND communityconnections.sendnotifications = 1 and users.retired = 0 and users.vouched = 1"

  has_many :activities


  has_many :communitylistconnections, :dependent => :destroy
  has_many :lists, :through => :communitylistconnections
  
  # meta communities
  has_many :metaconnections,  :foreign_key => 'includedcommunity_id',
                       :class_name => 'Metacommunityconnection',
                       :dependent => :destroy
  has_many :metacommunities,     :through => :metaconnections
  
  has_many :includedconnections,  :foreign_key => 'metacommunity_id',
                       :class_name => 'Metacommunityconnection',
                       :dependent => :destroy
  has_many :includedcommunities, :through => :includedconnections
  
  
  # institutions
  has_many :institutions, :foreign_key => 'institutionalteam_id'

  # topics for public site
  belongs_to :topic, :foreign_key => 'public_topic_id'
  
  has_many :cached_tags, :as => :tagcacheable
  
  named_scope :tagged_with_content_tag, lambda {|tagname| 
    {:include => {:taggings => :tag}, :conditions => "tags.name = '#{tagname}' AND taggings.tag_kind = #{Tag::CONTENT}"}
  }
  
  named_scope :tagged_with_shared_tag, lambda {|tagname| 
    {:include => {:taggings => :tag}, :conditions => "tags.name = '#{tagname}' AND taggings.tag_kind = #{Tag::SHARED}"}
  }
  
  # validations
  validates_uniqueness_of :name
  validates_presence_of :name, :entrytype
     
     
  
  named_scope :approved, :conditions => {:entrytype => Community::APPROVED}
  named_scope :usercontributed, :conditions => {:entrytype => Community::USERCONTRIBUTED}
  
  named_scope :filtered, lambda {|options| userfilter_conditions(options)}
  named_scope :displaylist, {:group => "#{table_name}.id",:order => "entrytype,name"}
  
  named_scope :launched, {:conditions => {:is_launched => true}}
  named_scope :public_list, {:conditions => ["show_in_public_list = 1 or is_launched = 1"]}
  
  named_scope :ordered_by_topic, {:include => :topic, :order => 'topics.name ASC, communities.public_name ASC'}
   
  before_create :clean_description_and_shortname, :show_in_public_if_approved
  before_update :clean_description_and_shortname, :show_in_public_if_approved

  def primary_content_tag_name(force_cache_update=false)
    self.cached_content_tags(force_cache_update)[0]
  end
    
  # returns a comma delimited of the tags - with the primary content tag name first in the list
  # used for community editing in the administrative interface for public communities
  def content_tag_names(force_cache_update=false)
    self.cached_content_tags(force_cache_update).join(Tag::JOINER)
  end  
  
  # this will silently strip out content tags in use by other communities
  # it's up to the controller level to deal with the warnings on this
  def content_tag_names=(taglist)
    # get content tags in use by other communities
    my_content_tags = tags_by_ownerid_and_kind(User.systemuserid,Tag::CONTENT)
    other_community_tags = Tag.community_content_tags - my_content_tags
    other_community_tag_names = other_community_tags.map(&:name)
    updatelist = Tag.castlist_to_array(taglist,true)
    primary = updatelist[0]
    
    # primary tag - first in the list
    if(!other_community_tag_names.include?(primary))
      self.replace_tags(primary,User.systemuserid,Tag::CONTENT_PRIMARY)
    end
    
    # okay do the others - updating the cached_tags for search
    self.replace_tags_with_and_cache(updatelist.reject{|tname| other_community_tag_names.include?(tname)},User.systemuserid,Tag::CONTENT)
           
    # now update my cached_content_tags and return those
    return self.cached_content_tags(true)
  end
    
  # returns an array of the names
  def cached_content_tags(force_cache_update=false)
    if(self.cached_content_tag_data.blank? or self.cached_content_tag_data[:primary_tag].blank? or self.cached_content_tag_data[:all_tags].blank? or force_cache_update)
      # get primary content tag first - should be only one - and if not, we'll force it anyway
      primary_tags = tags_by_ownerid_and_kind(User.systemuserid,Tag::CONTENT_PRIMARY)
      if(!primary_tags.blank?)
        tagarray = []
        primary_content_tag = primary_tags[0]
        tagarray << primary_content_tag
        # get the rest...
        other_content_tags = tags_by_ownerid_and_kind(User.systemuserid,Tag::CONTENT)
        other_content_tags.each do |tag| 
          if(tag != primary_content_tag)
            tagarray << tag
          end
        end
        tagarray += other_content_tags if !other_content_tags.blank?
      else
        tagarray = tags_by_ownerid_and_kind(User.systemuserid,Tag::CONTENT)
      end
      
      cachedata = {}
      if(!tagarray.blank?)
        cachedata[:primary_tag] = {:id => tagarray[0].id, :name => tagarray[0].name}
        cachedata[:all_tags] = {}
        tagarray.map{|t| cachedata[:all_tags][t.id] = t.name}
      end
      update_attribute(:cached_content_tag_data, cachedata)
      return tagarray.collect(&:name)
    else
      tagarray = []
      primary_tag_name = self.cached_content_tag_data[:primary_tag][:name] 
      tagarray << primary_tag_name    
      self.cached_content_tag_data[:all_tags].each do |id,name| 
        if(name != primary_tag_name)
          tagarray << name
        end
      end          
      return tagarray
    end
  end
  
  
  def clean_description_and_shortname
    if(!self.description.nil?)
      self.description = Hpricot(self.description).to_html 
    end
    
    if(self.shortname.blank?)
      self.shortname = self.name.gsub(/\W/,'').downcase
    else
      self.shortname = self.shortname.gsub(/\W/,'').downcase
    end
    
  end
  
  def show_in_public_if_approved
    if(self.entrytype == APPROVED)
      self.show_in_public_list = true
    end
  end
  
  def entrytype_to_s
    if !ENTRYTYPES[self.entrytype].nil?
      ENTRYTYPES[self.entrytype][:label]
    else
      "Unknown community type"
    end
  end
  
  def memberfilter_to_s
    if(self.entrytype == Community::SYSTEM)
      "Managed Membership"
    elsif !MEMBERFILTERS[self.memberfilter].nil?
      MEMBERFILTERS[self.memberfilter]
    else
      "Unknown community membership status"
    end
  end
  
  def shared_tag_list(limit=10,minweight=2)
    if(limit == 0 or limit == 'all')
      my_top_tags(:order => 'weightedfrequency DESC', :minweight => minweight)
    else
      my_top_tags(:order => 'weightedfrequency DESC', :limit => limit, :minweight => minweight)
    end
  end
    
  def user_tag_list(owner)
    self.tag_list_by_ownerid_and_kind(owner.id,Tag::USER)
  end
  
  def user_tag_displaylist(owner)
    return self.tag_displaylist_by_ownerid_and_kind(owner.id,Tag::USER)
  end
  
  def update_user_tags(taglist,owner)
    self.replace_tags_with_and_cache(taglist,owner.id,Tag::USER)
  end
  
  def remove_user_tags(owner)
    self.remove_tags_and_update_cache(self.user_tag_list(owner),owner.id,Tag::USER)
  end
    
  def system_sharedtags_displaylist
    return self.tag_displaylist_by_ownerid_and_kind(User.systemuserid,Tag::SHARED)
  end
  
  def tag_myself_with_systemuser_tags(taglist)
    self.replace_tags_with_and_cache(taglist,User.systemuserid,Tag::SHARED,AppConfig::configtable['systemuser_sharedtag_weight'])
  end
  
  def shared_tag_list_to_s(limit=10)
    shared_tag_list.map(&:name).sort.join(Tag::JOINER)
  end

  def modify_or_create_userconnection(user,options)
    user.modify_or_create_communityconnection(self,options) # handles lists, and metacommunities
  end
  
  def remove_user_from_leadership(user,connector,notify=true)
    activitycode = Activity::COMMUNITY_REMOVEDASLEADER
    notificationcode = notify ? Notification.translate_connection_to_code('removeleader') : Notification::NONE
    modify_or_create_userconnection(user, {:activitycode => activitycode,:notificationcode => notificationcode, :operation => 'remove', :connectiontype => 'leader', :connector => connector})
  end
  
  def remove_user_from_membership(user,connector,notify=true)
    activitycode = Activity::COMMUNITY_REMOVEDASMEMBER
    notificationcode = notify ? Notification.translate_connection_to_code('removemember') : Notification::NONE
    modify_or_create_userconnection(user, {:activitycode => activitycode,:notificationcode => notificationcode, :operation => 'remove', :connectiontype => 'member', :connector => connector})
  end
  
  def add_user_to_membership(user,connector,notify=true)
    activitycode = Activity::COMMUNITY_ADDEDASMEMBER
    notificationcode = notify ? Notification.translate_connection_to_code('addmember') : Notification::NONE
    modify_or_create_userconnection(user, {:activitycode => activitycode,:notificationcode => notificationcode, :operation => 'add', :connectiontype => 'member', :connector => connector})
  end
  
  def add_user_to_leadership(user,connector,notify=true)
    activitycode = Activity::COMMUNITY_ADDEDASLEADER
    notificationcode = notify ? Notification.translate_connection_to_code('addleader') : Notification::NONE
    modify_or_create_userconnection(user, {:activitycode => activitycode,:notificationcode => notificationcode, :operation => 'add', :connectiontype => 'leader', :connector => connector})
  end
  
  def invite_user(user,asleader,connector,notify=true)
    connectioncode = asleader ? Communityconnection::INVITEDLEADER : Communityconnection::INVITEDMEMBER
    activitycode = asleader ? Activity::COMMUNITY_INVITEDASLEADER : Activity::COMMUNITY_INVITEDASMEMBER
    connectaction = asleader ? 'inviteleader' : 'invitemember'
    notificationcode = notify ? Notification.translate_connection_to_code(connectaction) : Notification::NONE
    
    modify_or_create_userconnection(user, {:activitycode => activitycode, :notificationcode => notificationcode, :operation => 'add', :connectiontype => 'invited', :connector => connector, :connectioncode => connectioncode})
  end
  
  def rescind_user_invitation(user,connector,notify=true)
    activitycode = Activity::COMMUNITY_INVITATIONRESCINDED
    notificationcode = notify ? Notification.translate_connection_to_code('rescindinvitation') : Notification::NONE
    modify_or_create_userconnection(user, {:activitycode => activitycode, :notificationcode => notificationcode,:operation => 'remove', :connectiontype => 'invited', :connector => connector})
  end
  
  def mass_connect(userlist,options={})
    logger.debug "=================================== Inside mass_connect: #{self.attributes.inspect}"
    
    return if(userlist.blank?)
    
    # will do this ourselves - after
    options.merge({:no_list_update => true, :no_meta_update => true})
    
    # do each user
    userlist.each do |user|
      user.modify_or_create_communityconnection(self,options)           
    end
    
    # now update the lists
    self.update_lists
    
    # repeat for metacommunities, or recursion n. see recursion
    if(!self.metacommunities.empty?)
      metacommunities.each do |metacommunity|
        metaoptions = options.merge({:ismeta => true})
        metacommunity.mass_connect(userlist,metaoptions)
      end
    end
  end
  
  def mass_invite(userlist,connector,asleader,notify=true)
    activitycode = asleader ? Activity::COMMUNITY_INVITEDASLEADER : Activity::COMMUNITY_INVITEDASMEMBER
    connectioncode = asleader ? Communityconnection::INVITEDLEADER : Communityconnection::INVITEDMEMBER
    connectaction = asleader ? 'inviteleader' : 'invitemember'
    notificationcode = notify ? Notification.translate_connection_to_code(connectaction) : Notification::NONE
    # so that leaders and members don't get converted to invitations and existing invitations don't get another one
    connect_user_list = userlist - self.leaders - self.members - self.invited 
    self.mass_connect(connect_user_list,{:activitycode => activitycode, :notificationcode => notificationcode, :operation => 'add', :connectiontype => 'invited', :connector => connector, :connectioncode => connectioncode})
  end
  
  def mass_connect_as_member(userlist,connector,notify=true)
    activitycode = Activity::COMMUNITY_ADDEDASMEMBER
    notificationcode = notify ? Notification.translate_connection_to_code('addmember') : Notification::NONE
    # so that leaders don't get converted to members and existing members don't get added again
    connect_user_list = userlist - self.leaders - self.members
    self.mass_connect(connect_user_list,{:activitycode => activitycode, :notificationcode => notificationcode, :operation => 'add', :connectiontype => 'member', :connector => connector})
  end
  
  # yet another convenience function
  def mass_connect_as_member_from_mailing_list(listname,connector,notify=true)
    if(connector.nil?)
      return false
    end
    
    list = List.find_by_name(listname)
    if(list.nil?)
      return false
    end
    
    list_users = list.list_subscriptions.subscribers.map(&:user)
    self.mass_connect_as_member(list_users,connector,notify)
    return true
  end
  
  def mass_connect_as_invitedmember_from_mailing_list(listname,connector,notify=true)
    if(connector.nil?)
      return false
    end
    
    list = List.find_by_name(listname)
    if(list.nil?)
      return false
    end
    
    list_users = list.list_subscriptions.subscribers.map(&:user)
    self.mass_invite(list_users,connector,false,notify) # mass member only
    return true
  end
  
  
  def make_meta_connection(metacommunity,connectiontype,connector=nil)
    logger.debug "=================================== Inside make_meta_connection: #{self.attributes.inspect}"
    
    # ONLY SYSTEM COMMUNITIES CAN BE META COMMUNITIES FOR NOW
    # TODO: change?
    return if(metacommunity.entrytype != Community::SYSTEM)
    if connector.nil?
      connector = User.find(1)
    end
    # must have already been designated a metacommunity
    return if(!metacommunity.ismeta)
    
    # check for existing connection
    metaconnection = Metacommunityconnection.find(:first, :conditions => ['metacommunity_id = ? and includedcommunity_id = ?',metacommunity.id, self.id])
    if(metaconnection.nil?)
      # create the connection
      Metacommunityconnection.create(:metacommunity => metacommunity, :includedcommunity => self, :connectiontype => connectiontype)
    elsif(metaconnection.connectiontype != connectiontype)
      # just don't do anything
      return metaconnection
    end
    
    # mass add my group to the metacommunity members
    massoptions = {:operation => 'add', :connectiontype => 'member', :ismeta => true, :connector => connector}
    userlist = userlist_by_connectiontype(connectiontype)
    metacommunity.mass_connect(userlist,massoptions)
    return metaconnection
  end
  
  def drop_meta_connection(metacommunity,connectiontype,connector=nil)
    # ONLY SYSTEM COMMUNITIES CAN BE META COMMUNITIES FOR NOW
    # TODO: change?
    return if(metacommunity.entrytype != Community::SYSTEM)
    if connector.nil?
      connector = User.find(1)
    end
    # must have already been designated a metacommunity
    return if(!metacommunity.ismeta)
    
    # make sure there's actually a connection in place
    metaconnection = Metacommunityconnection.find(:first, :conditions => ['metacommunity_id = ? and includedcommunity_id = ?',metacommunity.id, self.id])
    
    return if(metaconnection.nil?)
    
    # mass remove my group to the metacommunity members
    massoptions = {:operation => 'remove', :connectiontype => 'member', :ismeta => true, :connector => connector}
    userlist = userlist_by_connectiontype(connectiontype)
    metacommunity.mass_connect(userlist,massoptions)
    
    metaconnection.destroy
  end
  
  def userlist_by_connectiontype(connectiontype)
    case connectiontype
    when 'leaders'
      return self.leaders
    when 'members'
      return self.members
    when 'wantstojoin'
      return self.wantstojoin
    when 'interest'
      return self.interest
    when 'invited'
      return self.invited
    when 'joined'
      return self.joined
    when 'interested'
      return self.interested
    else
      return []
    end
  end
  
  def listconnectionchecks(connectiontype,operation)
    case connectiontype
    when 'all'
      if(operation == 'add')
        adds = ['leaders','joined','interested']
        removes = []
      elsif(operation == 'remove')
        adds = []
        removes = ['leaders','joined','interested']
      end      
    when 'leader'
      if(operation == 'add')
        adds = ['leaders','joined','interested']
        removes = []
      elsif(operation == 'remove')
        adds = []
        removes = ['leaders','interested']
      end
    when 'member'
      if(operation == 'add')
        adds = ['joined']
        removes = ['leaders','interested']
      elsif(operation == 'remove')
        adds = []
        removes = ['joined']
      end
    when 'wantstojoin'
      if(operation == 'add')
        adds = ['interested']
        removes = ['leaders','joined']
      elsif(operation == 'remove')
        adds = []
        removes = ['interested']
      end
    when 'interest'
      if(operation == 'add')
        adds = ['interested']
        removes = ['leaders','joined']
      elsif(operation == 'remove')
        adds = []
        removes = ['interested']
      end
    when 'nointerest'
      if(operation == 'add')
        adds = []
        removes = ['leaders','joined','interested']
      end
    else
      adds = []
      removes = []
    end
    
    return [adds,removes]
  end
  
  def recent_community_activity(limit=20)
    Activity.filtered(:community => self, :communityactivity => 'all').find(:all, :limit => limit, :order => 'activities.created_at DESC')
  end
  
  def joined_agreement_count(status)
    self.joined_agreement_list(status).length
  end
  
  def joined_agreement_list(status)
    if(status == 'empty')
      findconditions = "contributor_agreement IS NULL"
    elsif(status == 'agree')
      findconditions = "contributor_agreement = 1"
    else
      findconditions = "contributor_agreement = 0"
    end
    
    return self.joined.find(:all, :conditions => ["#{findconditions}"])
  end
  
  
  def update_lists_with_user(user,operation,connectiontype)
    logger.debug "=================================== Inside update_lists_with_user: #{user.login} #{operation} #{connectiontype}"
    
    (adds,removes)= self.listconnectionchecks(connectiontype,operation)
    return if (adds.empty? and removes.empty?)
    
    
    return if(communitylistconnections.empty?)
    communitylistconnections.each do |listconnection|
      if(adds.include?(listconnection.connectiontype))
        listconnection.list.add_or_update_subscription(user)
        if(connectiontype == 'leader')
          listconnection.list.add_or_update_ownership(user)
        end
      end
      
      if(removes.include?(listconnection.connectiontype))
        listconnection.list.remove_subscription(user)
        if(connectiontype == 'leader' or connectiontype == 'all')
          listconnection.list.remove_ownership(user)
        end
      end
    end      
  end
  
  def update_lists()
    returnstats = {}
    return returnstats if(communitylistconnections.empty?)
    communitylistconnections.each do |listconnection|
      returnstats[listconnection.list] = self.update_list(listconnection.connectiontype,listconnection)
    end
    return returnstats
  end
  
  def update_list(connectiontype,suppliedconnection = nil)
    # special block if this is called by itself
    if(suppliedconnection.nil?)
      listconnection = Communitylistconnection.find_by_connectiontype_and_community_id(connectiontype,self.id)
    else
      listconnection = suppliedconnection
    end
    return {:subscriptions => 'none', :owners => 'none'} if(listconnection.nil?)
    
    substats = listconnection.list.update_subscriptions(userlist_by_connectiontype(listconnection.connectiontype))
    if(!self.leaders.empty? and connectiontype != 'listowners')
      ownerstats = listconnection.list.update_owners(self.leaders)
    end
    return {:subscriptions => substats, :owners => ownerstats.nil? ? 'none' : ownerstats}
  end
  
  def create_or_connect_to_list(listoptions,updatelist = true)
    connectiontype = listoptions.delete(:connectiontype)
    list = List.find_or_createnewlist(listoptions)
        
    if(!list.nil?)
      listconnection = Communitylistconnection.find_by_list_id_and_community_id(list.id,self.id)
      if(listconnection.nil?)
        listconnection = Communitylistconnection.create(:list => list, :community => self, :connectiontype => connectiontype)
        adminevent = AdminEvent.log_data_event(AdminEvent::CONNECT_LIST, {:listname => list.name, :communityname => self.name, :connectiontype => connectiontype})
      else
        listconnection.update_attribute(:connectiontype,connectiontype)
      end

      if(updatelist)
        managedoptions = {}
        managedoptions[:dropforeignsubscriptions] = listoptions[:dropforeignsubscriptions].nil? ? false : listoptions[:dropforeignsubscriptions]
        managedoptions[:dropunconnected] = listoptions[:dropunconnected].nil? ? false : listoptions[:dropunconnected]
        list.makemanaged(managedoptions)
        update_list(connectiontype)
      end
    end
    
    return list

  end
    
  def drop_nonjoined_taggings
    systemtaggings =  self.taggings.find(:all, :conditions => {:tag_kind => 'system'})
    systemtaggings.each do |tagging|
      if (!self.joined.include?(tagging.owner))
        tagging.destroy
      end
    end
  end
  
  def listconnection(connectiontype)
    Communitylistconnection.find_by_connectiontype_and_community_id(connectiontype,self.id)
  end
  
  # -----------------------------------
  # Class-level methods
  # -----------------------------------
    
  def self.communitytype_condition(communitytype)
    
    if(communitytype.nil?)
      return "communities.entrytype IN (#{Community::APPROVED},#{Community::USERCONTRIBUTED})"
    end
    
    case communitytype
    when 'approved'
      returncondition = "communities.entrytype = #{Community::APPROVED}"
    when 'usercontributed'
      returncondition = "communities.entrytype = #{Community::USERCONTRIBUTED}"
    else
      returncondition = "communities.entrytype IN (#{Community::APPROVED},#{Community::USERCONTRIBUTED})"
    end
    
    return returncondition      
  end
  
  
  def self.find_by_shortname_or_id(searchterm)
    community = find_by_id(searchterm)
    if(community.nil?)
      community = find_by_shortname(searchterm)
    end
    return community
  end
  
  def self.drop_nonjoined_taggings
    allcommunities = find(:all)
    allcommunities.each do |community|
      community.drop_nonjoined_taggings
    end
  end
  
  def self.per_page
    10
  end
    
  def self.get_approved_list
    approved.find(:all,:order => 'name ASC')
  end
  
  def self.newest(limit=5,entrytype='all')
    if(entrytype == 'all')
      find(:all,:order => 'created_at DESC', :limit => limit)
    else
      find(:all,:order => 'created_at DESC', :limit => limit, :conditions => ['entrytype = ?',entrytype])
    end
  end
  
  def self.search(opts = {})
    
    # TODO: search the description and the tags
    
    tmpterm = opts.delete(:searchterm)
    if tmpterm.nil?
      return nil
    end
    # remove any leading * to avoid borking mysql
    searchterm = tmpterm.gsub(/^\*/,'$').strip
    findvalues = {
      :findname => searchterm,
      :findtext => searchterm,
      :findtag => searchterm
    }
    conditions = ["name rlike :findname or description rlike :findtext or cached_tags.fulltextlist rlike :findtag",findvalues]
    
    finder_opts = {:joins => [:cached_tags], :conditions => conditions, :group => "communities.id"}
    
    dopaginate = opts.delete(:paginate)
    if(dopaginate)
      paginate(:all,opts.merge(finder_opts))
    else
      find(:all,opts.merge(finder_opts))
    end
  end
  
  
  def self.userfilter_conditions(options={})
    joins = [:users]
    
    conditions = []
    
    conditions << build_date_condition(options)
    
    if(options[:connectiontype])
      conditions << "#{Communityconnection.connection_condition(options[:connectiontype])}"
    else  
      conditions << "#{Communityconnection.connection_condition('joined')}"
    end
    
    if(options[:communitytype])
      conditions << "#{self.communitytype_condition(options[:communitytype])}"
    else
      conditions << "#{self.communitytype_condition('all')}"
    end
    
    # location, position, institution?
    conditions << User.build_association_conditions(options)
    
    # agreement status?
    conditions << User.build_agreement_status_conditions(options)
    
    if(options[:allusers].nil? or !options[:allusers])
      conditions << "#{User.table_name}.retired = 0 and #{User.table_name}.vouched = 1 and #{User.table_name}.id != 1"
    end  
        
    return {:joins => joins.compact, :conditions => conditions.compact.join(' AND ')}  
  end
  
  def self.userfilter_count(options={},returnarray = false)
    if(options[:countcommunities])
      countcolumn = "#{table_name}.id"
    else
      countcolumn = "DISTINCT(#{User.table_name}.id)"
    end
        
    countarray = self.filtered(options).count(countcolumn, :group => "#{table_name}.id")
    if(returnarray)
      return countarray
    else
      returnhash = {}
      countarray.map{|values| returnhash[values[0]] = values[1].to_i}
      return returnhash
    end
  end  

  # Gets the count of tags for the specified communities where the # of tags applied is >= 2 - which makes it way more complex
  def self.get_shared_tag_counts(community_ids,options={},inneroptions={})
    # scopes go on inner query - I'm sure that will bite this function in the arse later
    
    # construct inner query
    inneroptions[:select] = "#{table_name}.#{primary_key} as community_id, taggings.tag_id as tag_id, COUNT(taggings.tag_id) as frequency, SUM(taggings.weight) as weightedfrequency"
    inneroptions[:from] = "#{table_name}, #{Tagging.table_name}"

    innersql  = "SELECT #{inneroptions[:select]} "
    innersql << "FROM #{inneroptions[:from]} "

    #add_joins!(innersql, inneroptions, nil)

    innersql << "WHERE #{table_name}.#{primary_key} = taggings.taggable_id "
    innersql << "AND taggings.taggable_type = '#{ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s}' "
    ids_list_condition = community_ids.map { |id| "'#{id}'"}.join(',')
    innersql << "AND (#{table_name}.#{primary_key} IN (#{sanitize_sql(ids_list_condition)})) "
    innersql << "AND #{sanitize_sql(inneroptions[:conditions])} " if inneroptions[:conditions]
    innersql << "GROUP BY taggings.tag_id "
    if(!options[:minweight].nil?)
      innersql << "HAVING SUM(taggings.weight) >= #{inneroptions[:minweight]}"
    elsif(!options[:mincount].nil?)
      innersql << "HAVING COUNT(taggings.tag_id) >= #{inneroptions[:mincount]}"
    else # default to minweight >= 2
      innersql << "HAVING SUM(taggings.weight) >= 2"
    end
    add_order!(innersql, inneroptions[:order], nil)
    add_limit!(innersql, inneroptions, nil)
    add_lock!(innersql, inneroptions, nil)
    
    # construct outer query
    
    options[:select] = "#{table_name}.*, COUNT(DISTINCT(shared_tag_list.tag_id)) as shared_tag_count"
    options[:from] = "#{table_name}, (#{innersql}) AS shared_tag_list"

    sql  = "SELECT #{options[:select]} "
    sql << "FROM #{options[:from]} "
    sql << "WHERE #{table_name}.#{primary_key} = shared_tag_list.community_id "
    sql << "GROUP BY #{table_name}.#{primary_key} "
    add_order!(sql, options[:order], nil)
    add_limit!(sql, options, nil)
    add_lock!(sql, options, nil)
    
    find_by_sql(sql)
  end
        
end
