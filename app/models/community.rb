# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
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
  
  # hardcoded question wrangler community for AaE integration
  QUESTION_WRANGLERS_COMMUNITY_ID = 38

  # hardcoded institutional teams community for Institution integration
  INSTITUTIONAL_TEAMS_COMMUNITY_ID = 80
  
  UNKNOWN = 0
  
  # community types
  APPROVED = 1
  USERCONTRIBUTED = 2
  INSTITUTION = 3
  

  # labels and keys
  ENTRYTYPES = Hash.new
  ENTRYTYPES[APPROVED] = {:locale_key => 'approved', :allowadmincreate => true}
  ENTRYTYPES[USERCONTRIBUTED] = {:locale_key => 'user_contributed', :allowadmincreate => true}
  ENTRYTYPES[INSTITUTION] = {:locale_key => 'institution', :allowadmincreate => true}
  
           
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
  has_many :validusers, :through => :communityconnections, :source => :user, :conditions => "accounts.retired = 0 and accounts.vouched = 1"
  has_many :wantstojoin, :through => :communityconnections, :source => :user, :conditions => "communityconnections.connectiontype = 'wantstojoin' and accounts.retired = 0 and accounts.vouched = 1"
  has_many :joined, :through => :communityconnections, :source => :user, :conditions => "(communityconnections.connectiontype = 'member' OR communityconnections.connectiontype = 'leader') and accounts.retired = 0 and accounts.vouched = 1"
  has_many :members, :through => :communityconnections, :source => :user, :conditions => "communityconnections.connectiontype = 'member' and accounts.retired = 0 and accounts.vouched = 1"
  has_many :leaders, :through => :communityconnections, :source => :user, :conditions => "communityconnections.connectiontype = 'leader' and accounts.retired = 0 and accounts.vouched = 1"
  has_many :invited, :through => :communityconnections, :source => :user, :conditions => "communityconnections.connectiontype = 'invited' and accounts.retired = 0 and accounts.vouched = 1"
  has_many :interest, :through => :communityconnections, :source => :user, :conditions => "communityconnections.connectiontype = 'interest' and accounts.retired = 0 and accounts.vouched = 1"
  has_many :nointerest, :through => :communityconnections, :source => :user, :conditions => "communityconnections.connectiontype = 'nointerest' and accounts.retired = 0 and accounts.vouched = 1"
  
  has_many :interested, :through => :communityconnections, :source => :user, :conditions => "communityconnections.connectiontype IN ('interest','wantstojoin','leader') and accounts.retired = 0 and accounts.vouched = 1"


  belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
  has_many :notifyleaders, :through => :communityconnections, :source => :user, :conditions => "communityconnections.connectiontype = 'leader' AND communityconnections.sendnotifications = 1 and accounts.retired = 0 and accounts.vouched = 1"

  has_many :activities

  has_many :lists, :order => "lists.name"
  
  # institutions
  named_scope :institutions, :conditions => {:entrytype => INSTITUTION}
 
  # topics for public site
  belongs_to :topic, :foreign_key => 'public_topic_id'
  belongs_to :location
  belongs_to :logo
  belongs_to :homage, :class_name => "Page", :foreign_key => "homage_id"
  
  
  has_many :cached_tags, :as => :tagcacheable, :dependent => :destroy
  

  
  has_one :email_alias, :dependent => :destroy
  has_one  :google_group
  
  named_scope :tagged_with_content_tag, lambda {|tagname| 
    {:include => {:taggings => :tag}, :conditions => "tags.name = '#{tagname}' AND taggings.tagging_kind = #{Tagging::CONTENT}"}
  }
  
  named_scope :tagged_with_shared_tag, lambda {|tagname| 
    {:include => {:taggings => :tag}, :conditions => "tags.name = '#{tagname}' AND taggings.tagging_kind = #{Tagging::SHARED}"}
  }
  
  # validations
  validates_uniqueness_of :name
  validates_presence_of :name, :entrytype
     
     
  
  named_scope :approved, :conditions => {:entrytype => Community::APPROVED}
  named_scope :usercontributed, :conditions => {:entrytype => Community::USERCONTRIBUTED}
  named_scope :institution, :conditions => {:entrytype => Community::INSTITUTION}
  
  named_scope :filtered, lambda {|options| self.userfilter_conditions(options)}
  named_scope :displaylist, {:group => "#{table_name}.id",:order => "entrytype,name"}
  
  named_scope :launched, {:conditions => {:is_launched => true}}
  named_scope :notinstitutions, :conditions => ["entrytype != #{INSTITUTION}"]
  named_scope :public_list, {:conditions => ["show_in_public_list = 1 or is_launched = 1"]}
  
  named_scope :ordered_by_topic, {:include => :topic, :order => 'topics.name ASC, communities.public_name ASC'}
   
  before_save :clean_description_and_shortname, :flag_attributes_for_approved
  after_save :update_email_alias
  after_save :update_google_group

  def is_institution?
    return (self.entrytype == INSTITUTION)
  end
  
  
  def viewlabel
    if(self.entrytype == INSTITUTION)
      return 'institution'
    else
      return 'community'
    end
  end
  
  
  
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
    my_content_tags = tags_by_ownerid_and_kind(User.systemuserid,Tagging::CONTENT)
    other_community_tags = Tag.community_content_tags - my_content_tags
    other_community_tag_names = other_community_tags.map(&:name)
    updatelist = Tag.castlist_to_array(taglist,true)
    primary = updatelist[0]
    
    # primary tag - first in the list
    if(!other_community_tag_names.include?(primary) and !Tag::CONTENTBLACKLIST.include?(primary))
      self.replace_tags(primary,User.systemuserid,Tagging::CONTENT_PRIMARY)
    end
    
    # okay, do all the tags as CONTENT taggings - updating the cached_tags for search
    self.replace_tags_with_and_cache(updatelist.reject{|tname| (other_community_tag_names.include?(tname) or Tag::CONTENTBLACKLIST.include?(tname))},User.systemuserid,Tagging::CONTENT)
    
    # update the Tag model's community_content_tags
    cctags = Tag.community_content_tags({:all => true},true)
    if(self.is_launched?)
      Tag.community_content_tags({:launchedonly => true},true)       
    end
    
    # now update the cached content community for each tag
    cctags.each do |t|
      t.content_community(true)
    end
    
    # now update my cached_content_tags
    taglist = self.cached_content_tags(true)
    

    
    return taglist.join(Tag::JOINER)
  end
    
  # returns an array of the names
  def cached_content_tags(force_cache_update=false)
    if(self.cached_content_tag_data.blank? or self.cached_content_tag_data[:primary_tag].blank? or self.cached_content_tag_data[:all_tags].blank? or force_cache_update)
      # get primary content tag first - should be only one - and if not, we'll force it anyway
      primary_tags = tags_by_ownerid_and_kind(User.systemuserid,Tagging::CONTENT_PRIMARY)
      if(!primary_tags.blank?)
        tagarray = []
        primary_content_tag = primary_tags[0]
        tagarray << primary_content_tag
        # get the rest...
        other_content_tags = tags_by_ownerid_and_kind(User.systemuserid,Tagging::CONTENT)
        other_content_tags.each do |tag| 
          if(tag != primary_content_tag)
            tagarray << tag
          end
        end
        tagarray += other_content_tags if !other_content_tags.blank?
      else
        tagarray = tags_by_ownerid_and_kind(User.systemuserid,Tagging::CONTENT)
      end
      
      cachedata = {}
      if(!tagarray.blank?)
        cachedata[:primary_tag] = {:id => tagarray[0].id, :name => tagarray[0].name}
        cachedata[:all_tags] = {}
        tagarray.map{|t| cachedata[:all_tags][t.id] = t.name}
      end
      update_attribute(:cached_content_tag_data, cachedata)
    else
      cachedata =  self.cached_content_tag_data
    end

    returntagarray = []
    if(!cachedata[:primary_tag].nil?)    
      primary_tag_name = cachedata[:primary_tag][:name] 
      returntagarray << primary_tag_name    
      cachedata[:all_tags].each do |id,name| 
        if(name != primary_tag_name)
          returntagarray << name
        end
      end
    end          
    return returntagarray
  end
  
  
  def clean_description_and_shortname
    if(!self.description.nil?)
      self.description = Hpricot(self.description).to_html 
    end
    
    if(self.shortname.blank?)
      tmpshortname = self.name.gsub(/\W/,'').downcase
    else
      tmpshortname = self.shortname.gsub(/[^\w-]/,'').downcase
    end
    
    increment = 0
    checkname = tmpshortname
    
    while(EmailAlias.mail_alias_in_use?(checkname,self.new_record? ? nil : self) or Community.shortname_in_use?(checkname,self.new_record? ? nil : self))
      increment += 1
      checkname = "#{tmpshortname}_#{increment}"
    end
    self.shortname = checkname
  end
  
  def self.shortname_in_use?(shortname,checkcommunity = nil)
    conditions = "shortname = '#{shortname}'"
    if(checkcommunity)
      conditions += " AND id <> #{checkcommunity.id}"
    end
    count = Community.count(:conditions => conditions)
    return (count > 0)
  end
  
  def flag_attributes_for_approved
    if(self.entrytype == APPROVED)
      self.show_in_public_list = true
      self.connect_to_drupal = true
    end
  end
  
  def entrytype_to_s
    if !ENTRYTYPES[self.entrytype].nil?
      I18n.translate("communities.#{ENTRYTYPES[self.entrytype][:locale_key]}")     
    else
      I18n.translate("communities.unknown")     
      
      
    end
  end
  
  def memberfilter_to_s
    if !MEMBERFILTERS[self.memberfilter].nil?
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
    self.tag_list_by_ownerid_and_kind(owner.id,Tagging::USER)
  end
  
  def user_tag_displaylist(owner)
    return self.tag_displaylist_by_ownerid_and_kind(owner.id,Tagging::USER)
  end
  
  def update_user_tags(taglist,owner)
    self.replace_tags_with_and_cache(taglist,owner.id,Tagging::USER)
  end
    
  def system_sharedtags_displaylist
    return self.tag_displaylist_by_ownerid_and_kind(User.systemuserid,Tagging::SHARED)
  end
  
  def tag_myself_with_systemuser_tags(taglist)
    self.replace_tags_with_and_cache(taglist,User.systemuserid,Tagging::SHARED,AppConfig::configtable['systemuser_sharedtag_weight'])
  end
  
  def shared_tag_list_to_s(limit=10)
    shared_tag_list.map(&:name).sort.join(Tag::JOINER)
  end

  def modify_or_create_userconnection(user,options)
    user.modify_or_create_communityconnection(self,options) # handles lists
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
    return if(userlist.blank?)
    
    # will do this ourselves - after
    options.merge({:no_list_update => true})
    
    # do each user
    userlist.each do |user|
      user.modify_or_create_communityconnection(self,options)           
    end
    
    # now update the lists
    self.touch_lists
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
    
  def recent_community_activity(limit=7)
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
    
  def touch_lists
    self.lists.each do |l|
      l.touch
    end
  end
  
  def create_or_connect_to_list(listoptions)
    listoptions[:community_id] = self.id
    List.find_or_createnewlist(listoptions)
  end
    
  def drop_nonjoined_taggings
    systemtaggings =  self.taggings.find(:all, :conditions => {:tagging_kind => 'system'})
    systemtaggings.each do |tagging|
      if (!self.joined.include?(tagging.owner))
        tagging.destroy
      end
    end
  end
      
  def update_email_alias
    if(!self.email_alias.blank?)
      self.email_alias.update_attribute(:alias_type, (self.connect_to_google_apps? ? EmailAlias::COMMUNITY_GOOGLEAPPS : EmailAlias::COMMUNITY_NOWHERE))
    else
      self.email_alias = EmailAlias.create(:alias_type => (self.connect_to_google_apps? ? EmailAlias::COMMUNITY_GOOGLEAPPS : EmailAlias::COMMUNITY_NOWHERE), :community => self)            
    end
  end
  
  def update_google_group
    if(self.connect_to_google_apps?)
      if(!self.google_group.blank?)
        self.google_group.touch
      else
        self.create_google_group
      end
    else
      # do nothing
    end
    return true
  end
      
  # -----------------------------------
  # Class-level methods
  # -----------------------------------

    
  def self.communitytype_condition(communitytype)
    if(communitytype.nil?)
      return "communities.entrytype IN (#{Community::APPROVED},#{Community::USERCONTRIBUTED},#{Community::INSTITUTION})"
    end
    
    case communitytype
    when 'approved'
      returncondition = "communities.entrytype = #{Community::APPROVED}"
    when 'usercontributed'
      returncondition = "communities.entrytype = #{Community::USERCONTRIBUTED}"
    when 'institution'
      returncondition = "communities.entrytype = #{Community::INSTITUTION}"
    else
      returncondition = "communities.entrytype IN (#{Community::APPROVED},#{Community::USERCONTRIBUTED},#{Community::INSTITUTION})"
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
  
  # used for parameter searching
  def self.find_by_id_or_name_or_shortname(value)
   if(value.to_i != 0)
     community = find_by_id(value)
   end
   
   if(community.nil?)
     community = find_by_name(value)
     if(community.nil?)
       community = find_by_shortname(value)
     end
   end
   community
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
  
  def self.userfilteredparameters
    filteredparams_list = []
    # list everything that userfilter_conditions handles
    # build_date_condition
    filteredparams_list += [:dateinterval,:datefield]
    # build_entrytype_condition
    filteredparams_list += [{:entrytype => :integer}]
    # community params 
    filteredparams_list += [:community,:communitytype,:connectiontype]
    # build_association_conditions
    filteredparams_list += [:institution,:location,:position, :county]
    # agreement status
    filteredparams_list += [:agreementstatus]
    # allusers
    filteredparams_list += [{:allusers => :boolean}]
    filteredparams_list
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
  
  # get all content tag ids (including primary) for all communities
  def self.content_tag_ids
    content_tag_ids = Tagging.find(:all, :select => "DISTINCT(taggings.tag_id)", :conditions => "taggings.taggable_type = 'Community' AND (taggings.tagging_kind = '#{Tagging::CONTENT}' or taggings.tagging_kind = '#{Tagging::CONTENT_PRIMARY}')")
    return content_tag_ids.map{|tag| tag.tag_id}
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


  def ask_an_expert_group_url
    if(self.aae_group_id.blank?)
      nil
    else
      "#{AppConfig.configtable['ask_two_point_oh']}groups/#{self.aae_group_id}"
    end
  end 
    
end
