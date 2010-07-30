# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class LearnController < ApplicationController
  
  layout 'learn'
  
  before_filter :login_optional
  before_filter :login_required, :check_purgatory, :only => [:create_session, :edit_session, :delete_event]
  
  def index
    @upcoming_sessions = LearnSession.find(:all, :conditions => "session_start > '#{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')}'", :limit => 3, :order => "session_start ASC")
    @recent_sessions = LearnSession.find(:all, :conditions => "session_start < '#{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')}'", :limit => 10, :order => "session_start DESC")
    @recent_tags = Tag.find(:all, :select => 'DISTINCT tags.*', :joins => [:taggings], :conditions => {"taggings.tag_kind" => Tagging::SHARED, "taggings.taggable_type" => "LearnSession"}, :limit => 12, :order => "taggings.created_at DESC")
  end
  
  def event
    if params[:id].blank? or !@learn_session = LearnSession.find_by_id(params[:id])
      flash[:failure] = "Invalid id entered for learn session."
      redirect_to :action => :index
      return
    end
    
    @session_start = convert_timezone(@learn_session.time_zone, "UTC", @learn_session.session_start.to_time)
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
      
      @learn_session.session_start = params[:session_start]
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
        # store start time in the db as utc
        @learn_session.session_start = convert_timezone("UTC", @learn_session.time_zone, @learn_session.session_start.to_time)
        @learn_session.save
        
        # process tags
        if !params[:tags].blank?
          @learn_session.tag_with(params[:tags], User.systemuserid, Tagging::SHARED)
        end
        
        flash[:success] = "Learning lesson saved successfully!<br />Thank you for your submission!"
        redirect_to :action => :event, :id => @learn_session.id
      end
    # GET request for initial form display
    else
      @learn_session = LearnSession.new    
    end
  end
  
  def edit_session
    if params[:id].blank? or !@learn_session = LearnSession.find_by_id(params[:id])
      flash[:failure] = "Invalid id entered for learn session."
      redirect_to :action => :index
      return
    end
        
    if request.post?
      @learn_session.session_start = convert_timezone("UTC", params[:learn_session][:time_zone], params[:session_start].to_time) if (!params[:session_start].blank? and !params[:learn_session][:time_zone].blank?)
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
          @learn_session.replace_tags(params[:tags], User.systemuserid, Tagging::SHARED)
        else
          @learn_session.replace_tags('', User.systemuserid, Tagging::SHARED)
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
  
  def presenters_by_name
    #if a login/name was typed into the field to search for users
    name_str = params[:name]
    if name_str.blank?
      render :nothing => true
      return
    end
    
    @users = User.validusers.patternsearch(name_str).all(:limit => User.per_page)
    render :layout => false
  end
  
  def update_time_zone
    if request.post? and !params[:new_time_zone].blank? and !params[:id].blank? and learn_session = LearnSession.find_by_id(params[:id])
      # we need to do a timezone conversion here, take the time from the learn session and convert to the desired time zone
      time_obj = convert_timezone(params[:new_time_zone], "UTC", learn_session.session_start)
      time_zone_to_display = time_obj.time_zone.name
      time_to_display = time_obj.strftime("%l:%M %p")
      
      render :update do |page|
        page.replace_html :session_date_time, "<span id=\"time\">#{time_to_display.downcase} <span id=\"timezone\">#{format_time_zone(time_zone_to_display)}</span></span>" 
      end
    else
      return
    end
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
      return
    end
  end
  
  def change_my_connection
    @learn_session = LearnSession.find_by_id(params[:id])
    
    if(params[:connection] and params[:connection] == 'makeconnection')
       if(params[:connectiontype] == 'interested')
         @currentuser.update_connection_to_learn_session(@learn_session,LearnConnection::INTERESTED,true)
         UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "indicated interest in learn: #{@learn_session.title}")
       elsif(params[:connectiontype] == 'attended')
         @currentuser.update_connection_to_learn_session(@learn_session,LearnConnection::ATTENDED,true)
         UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "indicated attendance at learn: #{@learn_session.title}")
       end
     else
       if(params[:connectiontype] == 'interested')
         @currentuser.update_connection_to_learn_session(@learn_session,LearnConnection::INTERESTED,false)
         UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "removed interest in learn: #{@learn_session.title}")
       elsif(params[:connectiontype] == 'attended')
         @currentuser.update_connection_to_learn_session(@learn_session,LearnConnection::ATTENDED,false)
         UserEvent.log_event(:etype => UserEvent::PROFILE,:user => @currentuser,:description => "removed attendance at learn: #{@learn_session.title}")
       end
     end
    
    respond_to do |format|
      format.js
    end
  end
  
  
  
end
