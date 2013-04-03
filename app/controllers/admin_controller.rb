# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
class AdminController < ApplicationController
  before_filter :admin_required
  before_filter :check_purgatory
  before_filter :turn_off_right_column
  before_filter :sudo_required, :only => [:reload_config]
  
  layout 'pubsite'
  
  def index
    set_titletag("eXtension Pubsite Admin")
  end
    
  def manage_topics
    @right_column = false
    set_titletag("Manage Topics - Pubsite Admin")
    @topics = Topic.find(:all)
  end
  
  def destroy_topic
    if(topic = Topic.find_by_id(params[:id]))
      AdminEvent.log_event(@currentuser, AdminEvent::DELETE_TOPIC,{:topicname => topic.name})
      topic.destroy
    end
    flash[:notice] = 'Topic Deleted'
    redirect_to :action => :manage_topics
  end
  
  def create_topic
    topic = Topic.create(params[:topic])
    if(!topic.nil?)
      flash[:notice] = 'Topic Created'
      AdminEvent.log_event(@currentuser, AdminEvent::CREATE_TOPIC,{:topicname => topic.name})
    end
    redirect_to :action => :manage_topics
  end
  
  def manage_communities
    set_titletag("Manage Communities - Pubsite Admin")    
    @approved_communities =  Community.approved.all(:order => 'name')
    @other_public_communities = Community.usercontributed.public_list.all(:order => 'name')
  end
  
  def manage_community_logos
    set_titletag("Manage Community Logos - Pubsite Admin")
    if(!params[:communitytype].nil? and params[:communitytype] == 'institutions')  
      @communitieslist = Community.institutions.all(:order => 'name')
    else
      @communitieslist = Community.approved.all(:order => 'name') + Community.usercontributed.public_list.all(:order => 'name')
    end
  end
  
  def edit_community_logo
    @community = Community.find_by_id(params[:id])
    if(@community.nil?)
      flash[:error] = 'Invalid community'
      redirect_to :action => :index
    end
    @logo = @community.logo
    if(request.post?)
      @newlogo = Logo.new(params[:logo])
      @newlogo.logotype = Logo::COMMUNITY
      if @newlogo.save
        @logo.destroy if !(@logo.nil?)
        @community.update_attribute(:logo_id, @newlogo.id)
        flash[:notice] = 'Logo was successfully uploaded.'
        redirect_to(:action => 'manage_community_logos', :communitytype => (@community.is_institution? ? 'institutions' : 'approved'))
      end
    end
  end
  
  def delete_community_logo
    @community = Community.find_by_id(params[:id])
    if(@community.nil?)
      flash[:error] = 'Invalid community'
      redirect_to :action => :index
    end
    @community.logo.destroy
    flash[:notice] = 'Logo was successfully removed.'
    redirect_to(:action => 'manage_community_logos', :communitytype => (@community.is_institution? ? 'institutions' : 'approved'))
  end
  
  def manage_institutions
    set_titletag("Manage Institutions - Pubsite Admin")    
    @landgrant_institutions =  Community.institutions.all(:include => :location, :order => 'locations.abbreviation')
  end
    
  def manage_locations_office_links
    set_titletag("Manage Office Links - Pubsite Admin")    
    @locations =  Location.displaylist
  end
  
  def edit_location_office_link
    set_title('Edit Location Office Link')
    set_titletag("Edit Location Office Link - Pubsite Admin")
    @location = Location.find(params[:id])    
  end
  
  def update_location_office_link
    @location =  Location.find(params['id'])
    oldlink = @location.office_link
    @location.office_link = params['location']['office_link']

    if @location.save
      AdminEvent.log_event(@currentuser, AdminEvent::UPDATE_LOCATION_OFFICE_LINK,{:location_id => @location.id, :location_name => @location.name, :oldlink => oldlink, :newlink => @location.office_link})
      flash[:notice] = 'Location Updated'
    else
      flash[:notice] = 'Error updating location'
    end
    redirect_to :action => :manage_locations_office_links

  end
    
  def update_public_community
    @community =  Community.find(params['id'])
    @community.public_topic_id = params['community']['public_topic_id']
    @community.public_description = params['community']['public_description']
    @community.public_name = params['community']['public_name']
    @community.is_launched = ( params['community']['is_launched'] ? true : false)
    @community.homage_name = params['community']['homage_name']
    @community.aae_group_id = params['community']['aae_group_id']

  
    # sanity check tags
    if(params['community']['content_tag_names'].blank?)
      flash[:notice] = "You must specify a resource area tag for publishing communities"
      return(render(:action => "edit_public_community"))
    end

    # sanity check tag names
    this_community_content_tags = @community.tags_by_ownerid_and_kind(User.systemuserid,Tagging::CONTENT)
    other_community_tags = Tag.community_content_tags({:all => true},true) - this_community_content_tags
    other_community_tag_names = other_community_tags.map(&:name)
    updatelist = Tag.castlist_to_array(params['community']['content_tag_names'],true)
    invalid_tags = []
    updatelist.each do |tagname|
      if(other_community_tag_names.include?(tagname) or Tag::CONTENTBLACKLIST.include?(tagname))
        invalid_tags << tagname
      end
    end
    
    if(!invalid_tags.blank?)
      flash[:notice] = "The following tag names are in use by other communities or are not allowed for community use: #{invalid_tags.join(Tag::JOINER)}"
      return(render(:action => "edit_public_community"))
    end
        
    if @community.save
      flash[:notice] = 'Community Updated'
      @community.content_tag_names=(params['community']['content_tag_names'])
      AdminEvent.log_event(@currentuser, AdminEvent::UPDATE_PUBLIC_COMMUNITY,{:community_id => @community.id, :community_name => @community.name})
      # cache updates - this is kind of a hack
      if(@community.is_launched_changed?)
        Tag.community_content_tags({:launchedonly => true},true)
      end
              
      redirect_to :action => :manage_communities
    else
      flash[:notice] = 'Error updating community'
      return(render(:action => "edit_public_community"))
    end
  end
    
  def edit_public_community
    set_title('Edit Community Public Options')
    set_titletag("Edit Community - Pubsite Admin")
    @community = Community.find(params[:id])
  end
  
  def update_public_institution
    @institution =  Community.find(params['id'])
    @institution.referer_domain = params['institution']['referer_domain']
    @institution.public_uri = params['institution']['public_uri']

    if @institution.save
      flash[:notice] = 'Institution Updated'
      AdminEvent.log_event(@currentuser, AdminEvent::UPDATE_PUBLIC_INSTITUTION,{:institution_id => @institution.id, :institution_name => @institution.name})
      
    else
      flash[:notice] = 'Error updating institution'
    end
    redirect_to :action => :manage_institutions
  end
    
  def edit_public_institution
    set_title('Edit Institution Public Options')
    set_titletag("Edit Institution - Pubsite Admin")
    @institution = Community.find(params[:id])
  end
  
  def show_config
  end
  
  def special_pages
  end  
  
  def category_tag_redirects
  end
    
  def reload_config
    AppConfig.load_config
    redirect_to :action => :show_config 
  end
  
  # list recent notifications
  def notifications
    dateinterval = params[:dateinterval] || 'withinlastweek'
    @notifications = Notification.find(:all, :include => [:user,:creator], :conditions => Notification.build_date_condition({:dateinterval => dateinterval}), :order => 'created_at DESC')
  end
  
end
