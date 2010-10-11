# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class LearnController < ApplicationController
  
  layout 'learn'
  
  before_filter :login_optional
  before_filter :login_required, :check_purgatory, :only => [:create_session, :edit_session, :delete_event, :connect_to_session, :time_zone_check]
   
  
  def index
    @upcoming_sessions = LearnSession.find(:all, :conditions => "session_start > '#{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')}'", :limit => 3, :order => "session_start ASC")
    @recent_sessions = LearnSession.find(:all, :conditions => "session_start < '#{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')}'", :limit => 15, :order => "session_start DESC")
    @recent_tags = Tag.find(:all, :select => 'DISTINCT tags.*', :joins => [:taggings], :conditions => {"taggings.tagging_kind" => Tagging::SHARED, "taggings.taggable_type" => "LearnSession"}, :limit => 30, :order => "taggings.created_at DESC")
  end
  
  def event
    if params[:id].blank? or !@learn_session = LearnSession.find_by_id(params[:id])
      flash[:failure] = "Invalid id entered for learn session."
      redirect_to :action => :index
      return
    end
  
    @connected_users = {}
    @learn_session_creator = @learn_session.creator
    if @learn_session.event_started?
      attended = @learn_session.connected_users(LearnConnection::ATTENDED)
      interested = @learn_session.connected_users(LearnConnection::INTERESTED)
      attended.each do |u|
        @connected_users[u.id] = {:primaryconnectiontype => LearnConnection::ATTENDED, :user => u}
      end
      interested.each do |u|
        if(@connected_users[u.id].blank?)
          @connected_users[u.id] = {:primaryconnectiontype => LearnConnection::INTERESTED, :user => u}
        end
      end
    else
      interested = @learn_session.connected_users(LearnConnection::INTERESTED)
      interested.each do |u|
        @connected_users[u.id] = {:primaryconnectiontype => 'interest', :user => u}
      end
    end
    
    # set timezone to either the people profile pref for the user or the time zone selected for the session
    if @currentuser.nil? or !@currentuser.has_time_zone?
      @session_start = @learn_session.session_start.in_time_zone(@learn_session.time_zone) 
    # Time.zone is already set in the hook for controller method load, 
    # so we're good here (time is auto-updated) if the user has a timezone selected in their people profile
    else  
      @session_start = @learn_session.session_start
    end
  end
  
  def login_redirect
    session[:return_to] = params[:return_back]
    redirect_to :controller => 'people/account', :action => :login
  end
  
  def events
    if(!params[:sessiontype].blank? and ['recent','upcoming','myattended','myinterested','by_tag'].include?(params[:sessiontype]))
      if params[:sessiontype] == 'recent'
        @page_title = 'Recent Learn Sessions'
        @learn_sessions = LearnSession.paginate(:all, 
                                                :conditions => "session_start < '#{Time.now.utc.to_s(:db)}'", 
                                                :order => "session_start DESC",
                                                :page => params[:page])
      elsif params[:sessiontype] == 'upcoming'
        @page_title = 'Upcoming Learn Sessions'
        @learn_sessions = LearnSession.paginate(:all, 
                                                :conditions => "session_start > '#{Time.now.utc.to_s(:db)}'", 
                                                :order => "session_start ASC",
                                                :page => params[:page])        
      elsif params[:sessiontype] == 'myattended'
        @page_title = 'My Attended Learn Sessions'
        @learn_sessions = @currentuser.learn_sessions.paginate(:all, :conditions => "connectiontype = #{LearnConnection::ATTENDED}", :order => "session_start DESC",:page => params[:page])
      elsif params[:sessiontype] == 'myinterested'
        @page_title = 'My Interested Learn Sessions'
        @learn_sessions = @currentuser.learn_sessions.paginate(:all, :conditions => "connectiontype = #{LearnConnection::INTERESTED}", :order => "session_start DESC",:page => params[:page])
      elsif params[:sessiontype] == 'by_tag'
        if !params[:tag].blank? 
          @tag_param = params[:tag]
          event_tag = Tag.find_by_name(@tag_param)
          if event_tag
            @learn_sessions = event_tag.learn_sessions.paginate(:all, :order => "session_start DESC", :page => params[:page])
          else
            @learn_sessions = []
          end
        else
          flash[:failure] = "Invalid tag name"
          redirect_to :action => :index
        end
        @page_title = "Learn Sessions Tagged with '#{@tag_param}'"
      end
      
    else
      @page_title = 'All Learn Sessions'
      @learn_sessions = LearnSession.paginate(:all,
                                              :order => "session_start DESC",
                                              :page => params[:page])
    end
  end
  
  def create_session
    @scheduled_sessions = LearnSession.find(:all, :conditions => "session_start > '#{Time.now.utc.to_s(:db)}'", :limit => 20, :order => "session_start ASC")
    if request.post?
      @learn_session = LearnSession.new(params[:learn_session])

      # store start time in the db as utc relative to the specified time_zone
      if(!params[:session_start].blank?)      
        begin
          Time.zone = @learn_session.time_zone
          @learn_session.session_start = Time.zone.parse(params[:session_start])
        rescue
          flash[:error] = 'Invalid date and time specified'
          return render :template => '/learn/create_session'
        end
      end
      
      
      @learn_session.creator = @currentuser
      @learn_session.last_modifier = @currentuser
      
      # process presenters
      if !params[:presenter_list_to_save].blank?
        presenter_list = params[:presenter_list_to_save]
        presenter_array = presenter_list.split(',')
        presenter_array.uniq.each do |presenter_id|
          if !(user = User.find_by_id(presenter_id))
            @learn_session.errors.add("One of the presenters was not found in the eXtension ID user system.<br />Please include only those with eXtension IDs.")
            render :template => '/learn/create_session'
            return
          else
            @learn_connection = LearnConnection.new(:email => user.email, :user => user, :connectiontype => LearnConnection::PRESENTER)
            @learn_session.learn_connections << @learn_connection
          end
        end
      end
      # end of processing presenters
      
      # let's see if we can save it all...
      if !@learn_session.valid?
        render :template => '/learn/create_session'
        return
      else        
        @learn_session.save
        
        # process tags
        if !params[:tags].blank?
          # create new tags for learn session and create the cached_tags for search
          @learn_session.tag_with_and_cache(params[:tags], User.systemuserid, Tagging::SHARED)
        end
        
        flash[:success] = "Learning lesson saved successfully!<br />Thank you for your submission!"
        redirect_to :action => :event, :id => @learn_session.id
      end
    # GET request for initial form display
    else
      @learn_session = LearnSession.new(:session_length => 30)
    end
  end
  
  def edit_session
    if params[:id].blank? or !@learn_session = LearnSession.find_by_id(params[:id])
      flash[:failure] = "Invalid id entered for learn session."
      redirect_to :action => :index
      return
    end
        
    if request.post?
  
      # store start time in the db as utc relative to the specified time_zone
      if(!params[:session_start].blank?)
        begin
          if(params[:learn_session][:time_zone].blank?)
            Time.zone = @learn_session.time_zone
          else
            Time.zone = params[:learn_session][:time_zone]
          end
          @learn_session.session_start = Time.zone.parse(params[:session_start])
        rescue
          flash[:error] = 'Invalid date and time specified'
          return render :template => '/learn/create_session'
        end
      end
      
      @learn_session.last_modifier = @currentuser
      
      # process presenters
      # clear out presenters for this learn session first
      @learn_session.learn_connections.find(:all, :conditions => {:connectiontype => LearnConnection::PRESENTER}).each{|lc| lc.delete}
      
      if !params[:presenter_list_to_save].blank?
        presenter_list = params[:presenter_list_to_save]
        presenter_array = presenter_list.split(',')
        presenter_array.uniq.each do |presenter_id|
          if !(user = User.find_by_id(presenter_id))
            @learn_session.errors.add("One of the presenters was not found in the eXtension ID user system.<br />Please include only those with eXtension IDs.")
            render :template => '/learn/edit_session'
            return
          else
            @learn_connection = LearnConnection.new(:email => user.email, :user => user, :connectiontype => LearnConnection::PRESENTER)
            @learn_session.learn_connections << @learn_connection
          end
        end
      end
      # end of processing presenters
      if @learn_session.update_attributes(params[:learn_session])
        # process tags
        if !params[:tags].blank?
          @learn_session.replace_tags_with_and_cache(params[:tags], User.systemuserid, Tagging::SHARED)
        else
          @learn_session.replace_tags_with_and_cache('', User.systemuserid, Tagging::SHARED)
        end
        flash[:success] = "Learn session updated successfully!"
        redirect_to :action => :event, :id => @learn_session.id
        return
      else
        render :template => '/learn/edit_session'
        return
      end
    end
  end
  
  def profile
    if(@showuser = User.find_by_login(params[:id]))
      @sessions_presented = @showuser.learn_sessions_presented.find(:all, :order => "session_start desc" )
      # TODO: show public attributes
      # if(!@currentuser)
      #   @publicattributes = @showuser.public_attributes
      # end
    end
  end
  
  def presenters_by_name
    #if a login/name was typed into the field to search for users
    name_str = params[:name]
    if name_str.blank?
      render :nothing => true
      return
    end
    
    @users = User.notsystem.validusers.patternsearch(name_str).all(:limit => User.per_page)
    render :layout => false
  end
    
  def delete_event
    if request.post? and @currentuser
      if !params[:id].blank? and learn_session = LearnSession.find_by_id(params[:id])
        learn_session.destroy
        flash[:success] = "Learn session successfully deleted."
      else
        flash[:failure] = "Learn session referenced does not exist."
      end
    end
    redirect_to :action => :index
  end
  
  def search_sessions
    if params[:q].blank?
      flash[:warning] = "Empty search term"
      return redirect_to :action => 'index'
    end
    
    @search_query = params[:q]
    search_term = @search_query.gsub(/\\/,'').gsub(/^\*/,'$').gsub(/\+/,'').strip
    
    # exact match?
    if(exact = LearnSession.find(:first, :conditions => {:title => search_term}))
      return redirect_to :action => :event, :id => exact.id
    end
    
    # query twice, first by title, and then by description and tags
    @title_list = LearnSession.find(:all, :conditions => ["title like ?",'%' + search_term + '%'], :order => "title" )
    @description_and_tags_list = LearnSession.find(:all, :joins => [:cached_tags], :conditions => ["description like ? or cached_tags.fulltextlist like ?",'%' + search_term + '%','%' + search_term + '%'], :order => "title" )
    
    @learn_session_list = @title_list | @description_and_tags_list
  end
  
  def add_remove_presenters
    if request.post?
      if !params[:user_id].blank? and user = User.find_by_id(params[:user_id].to_i)
        # no current presenters for a session
        if params[:presenter_ids].blank?
          # if we're adding a presenter
          if !params[:add].blank? and params[:add] == "1"
            # populates current presenters with removal links on the session form
            users = [user]
            # user_ids are what's passed into the presenters hidden field to cause the presenters to be saved when the session is saved
            user_ids = user.id.to_s
          # shouldn't happen
          else
            return
          end
        else
          # add presenter
          if !params[:add].blank? and params[:add] == "1"
            # see above explanation for users
            users = User.find(params[:presenter_ids].split(',')).to_a << user
          # remove presenter
          elsif !params[:remove].blank? and params[:remove] == "1"
            # see above explanation for users
            users = User.find(params[:presenter_ids].split(',')).to_a - [user]
          # shouldn't happen
          else
            return
          end
          # see above explanation for user_ids
          if users.length > 0
            user_ids = users.collect{|u| u.id.to_s}.join(',')
          else
            user_ids = ''
          end
        end
            
        render :update do |page|
          page << "$('presenter_list_to_save').value = '#{user_ids}'" 
          page.replace_html :presenters_to_save, :partial => 'presenters', :locals => {:users => users}
        end
      else
        return
      end
    else
      redirect_to :index
      return
    end
  end
  
  def time_zone_check
    @learn_session = LearnSession.find_by_id(params[:id])
    if(!@learn_session)
      flash[:failure] = "Unable to find specified learn session."
      return redirect_to(:action => :index)
    end
    
    if(@currentuser.has_time_zone?)
      return redirect_to(:action => :event, :id => @learn_session.id)
    else
      return redirect_to(:controller => 'people/profile', :action => :edit)
    end
      
  end
  
  def connect_to_session
    @learn_session = LearnSession.find_by_id(params[:id])
    if(!@learn_session)
      flash[:failure] = "Unable to find specified learn session."
      return redirect_to(:action => :index)
    end
    
    return redirect_to(:action => :event, :id => @learn_session.id)
  end
  
  def change_my_connection
    if request.post?
      @learn_session = LearnSession.find_by_id(params[:id])
      @connectiontype = params[:connectiontype]
      if(params[:connection] and params[:connection] == 'makeconnection')
         if(@connectiontype == 'interested')
           @currentuser.update_connection_to_learn_session(@learn_session,LearnConnection::INTERESTED,true)
           UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "indicated interest in learn: #{@learn_session.title}")
         elsif(@connectiontype == 'attended')
           @currentuser.update_connection_to_learn_session(@learn_session,LearnConnection::ATTENDED,true)
           UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "indicated attendance at learn: #{@learn_session.title}")
         end
       else
         if(@connectiontype == 'interested')
           @currentuser.update_connection_to_learn_session(@learn_session,LearnConnection::INTERESTED,false)
           UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "removed interest in learn: #{@learn_session.title}")
         elsif(@connectiontype == 'attended')
           @currentuser.update_connection_to_learn_session(@learn_session,LearnConnection::ATTENDED,false)
           UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "removed attendance at learn: #{@learn_session.title}")
         end
       end
     
       @connected_users = {}
       if @learn_session.event_started?
         attended = @learn_session.connected_users(LearnConnection::ATTENDED)
         interested = @learn_session.connected_users(LearnConnection::INTERESTED)
         attended.each do |u|
           @connected_users[u.id] = {:primaryconnectiontype => LearnConnection::ATTENDED, :user => u}
         end
         interested.each do |u|
           if(@connected_users[u.id].blank?)
             @connected_users[u.id] = {:primaryconnectiontype => LearnConnection::INTERESTED, :user => u}
           end
         end
       else
         interested = @learn_session.connected_users(LearnConnection::INTERESTED)
         interested.each do |u|
           @connected_users[u.id] = {:primaryconnectiontype => 'interest', :user => u}
         end
       end
    
      respond_to do |format|
        format.js
      end
    else
      redirect_to :index
      return
    end
  end
  
end
