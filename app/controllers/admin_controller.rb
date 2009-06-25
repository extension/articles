# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
require 'zip_code_to_state'
class AdminController < DataController
  def index
    set_title('Administration')
    set_titletag("Site Admin - eXtension")
    @valid_key = has_verified_akismet_key?
    @right_column = false    
  end
  
  def add_admin
    set_title('Add an Admin')
    set_titletag("Add an Admin - eXtension Site Admin")
    @users = User.find(:all, :include => :roles)
    @right_column = false
  end
  
  def add_tag
    community = Community.find(params[:id])
    community.tags << Tag.find(params[:tag_id])
    redirect_to :action => :edit_community, :id => params[:id]
  end
  
  def remove_tag
    community = Community.find(params[:id])
    # can't delete the last tag
    if(community.tags.length == 1)
      flash[:warning] = "Each community must have at least one tag.  You can't delete the last tag."
      redirect_to :action => :edit_community, :id => params[:id]
      return
    end
    tag = Tag.find(params[:tag_id])
    community.tags.delete(tag)
    redirect_to :action => :edit_community, :id => params[:id]
  end
  
  # def remove_community
  #   Community.find(params[:id]).destroy
  #   redirect_to :action => :manage_communities
  # end
  
  def toggle_admin
    @user = User.find(params[:id])
    @user.toggle_admin
    render :partial => 'toggle_admin'
  end
  
  def users
    @term = params[:term]
    unless @term.nil? or @term.blank?
      conditions = ["(full_name RLIKE :term or email RLIKE :term or identity_url RLIKE :term)"]
      conditions << { :term => @term }
    end
    @right_column = false
    set_title('User List')
    set_titletag("Public Site User List - eXtension Site Admin")
    @users = User.paginate(:order => 'full_name', :conditions => conditions,
                           :per_page => params[:per_page] || 50, :page => params[:page] || 1)
  end
  
  def user
    if !params[:id] || !(@user = User.find_by_id(params[:id]))
      flash[:warning] = 'No such user.'
      request.env["HTTP_REFERER"] ? (redirect_to :back) : (redirect_to :action => 'users')
      return
    end
  end
  
  def manage_topics
    @right_column = false
    set_title('Manage Topics')
    set_titletag("Manage Topics - eXtension Site Admin")
    @topics = Topic.find(:all)
  end
  
  def destroy_topic
    Topic.destroy(params[:id])
    redirect_to :action => :manage_topics
  end
  
  def create_topic
    Topic.create(params[:topic])
    redirect_to :action => :manage_topics
  end
  
  def manage_communities
    @right_column = false
    set_title('Manage Communities', 'Update a communities description')
    set_titletag("Manage Communities - eXtension Site Admin")
    @communities =  Community.find_all_sorted
    @tags = Tag.find :all, :conditions => 'community_id is NULL', :order => 'name'    
  end
  
  def create_community
    @right_column = false
    @community = Community.new params['community']
    if @community.save
      tag = Tag.find(params['tag_id'])
      tag.community_id = @community.id
      tag.save
      flash[:notice] = 'Community Created'
    else
      flash[:notice] = 'Error updating community'
    end
    redirect_to :action => :manage_communities
  end
  
  def update_community_description
    @community =  Community.find(params['id'])
    @community.public_topic_id = params['community']['public_topic_id']
    @community.public_description = params['community']['public_description']
    @community.public_name = params['community']['public_name']
    @community.is_launched = ( params['community']['is_launched'] ? true : false)

    if @community.save
      flash[:notice] = 'Community Updated'
    else
      flash[:notice] = 'Error updating community'
    end
    redirect_to :action => :manage_communities
  end
    
  def edit_community
    @right_column = false
    set_title('Edit Community')
    set_titletag("Edit Community - eXtension Site Admin")
    @community = Community.find(params[:id], :include => :tags)
  end
  
  def retrieve_wikis
    WikiFeed.retrieve_wikis
    WikiChangesFeed.retrieve_wikis
    finished_retrieving("Wiki articles")
  rescue Exception => e
    handle_feed_error(e, WikiFeed)
  end
    
  def retrieve_events
    XCal.retrieve_events
    finished_retrieving("Events")
  rescue Exception => e
    handle_feed_error(e, XCal)
  end
  
  def retrieve_faqs
    Heureka.retrieve_faqs
    finished_retrieving("FAQs")
  rescue Exception => e
    handle_feed_error(e, Heureka)
  end
    
  #get updated list of subcategories from internal faq application
  def retrieve_subcats
    Category.import_subcats
    finished_retrieving("Subcategory")
  rescue Exception => e
    handle_feed_error(e, Category)
  end
  
  def retrieve_external_articles
    ExternalArticleFeed.retrieve_feeds
    finished_retrieving("External Feed")
  rescue Exception => e
    backtrace = e.backtrace.join("\n")
    flash[:error] = "Unsucessfully retrieved items from the feed."
    MainMailer.deliver_feed_error("External feed", "#{e}\n #{backtrace}")
    redirect_to :action => "index"
  end
    
  def check_authorization 
    if current_user == :false || ! has_right?(current_user)
      bounce_unauthorized_user
      return false 
    end 
  end 
  
  def edit_roles
    set_title('Edit Roles')
    set_titletag("Edit User Roles - eXtension Site Admin")
    @user = User.find(params[:id], :include => :roles)
    @roles =  Role.find(:all)
    @right_column = false
    
    # do extra processing if this is a form submission
    if request.post?
      
      # if no checkboxes are checked, no values will be submitted, so give the submission a blank array of role ids
      new_roles = params[:user].nil? ? [] : params[:user][:role_ids]
      
      # an admin cannot strip himself of the admin role
      puts new_roles.inspect
      if (current_user == @user) and (!new_roles.include? Role.find_by_name('Administrator').id.to_s)
        @user.roles = [ Role.find_by_name("Administrator") ]
        flash[:notice] = "You may not remove your own administrative role."
      else # zero out roles and add them back in from the submitted parameters
        flash[:notice] = "Roles successfully saved."
        @user.roles = []
      end
      
      # add roles to user's roles collection proxy
      new_roles.each do |role_id|
        @user.roles << Role.find(role_id)
      end
    end
  end
  
  def add_role
    @user = User.find(params[:id])
    if(@user.nil?)
      return redirect_to(:action => 'users')
    end
      
    @role = Role.find(params[:role_id])
    @user.roles << @role
    redirect_to :action => 'edit_roles', :id => @user.id
  end
  
  private


  def finished_retrieving(what)
    ActiveRecord::Base::logger.debug "Imported #{what} at: " + Time.now.to_s    
    flash[:notice] = "#{what} articles retrieved."
    redirect_to :action => "index"
  end
  
  def handle_feed_error(e, feed)
    backtrace = e.backtrace.join("\n")
    flash[:error] = "Unsucessfully retrieved items from the feed."
    MainMailer.deliver_feed_error(feed.full_url, "#{e}\n #{backtrace}")
    redirect_to :action => "index"
  end
  
  protected
      
  def check_self_demotion user_in_question
    (user_in_question == current_user and user_in_question.is_admin?)
  end  
end
