# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class LearnController < ApplicationController
  
  layout 'learn'
  
  before_filter :login_required
  before_filter :check_purgatory
  
  def index
    
  end
  
  def create_session
    if request.post?
      @learn_session = LearnSession.new(params[:learn_session])
      @learn_session.session_start = params[:session_start]
      @learn_session.session_end = params[:session_end]
      
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
        creator_connection = LearnConnection.new(:email => @currentuser.email, :user => @currentuser, :connectiontype => LearnConnection::CREATOR)
        @learn_session.learn_connections << creator_connection
        @learn_session.save
        flash[:success] = "Learning lesson saved successfully!<br />Thank you for your submission!"
        redirect_to :action => :index
      end
    # GET request for initial form display
    else
      @learn_session = LearnSession.new    
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
  
  def add_to_presenters
    if request.post?
      if !params[:user_id].blank? and user = User.find_by_id(params[:user_id])
        params[:presenter_ids].blank? ? users = [user] : users = User.find(params[:presenter_ids].split(',').each{|pid| pid.to_i}).to_a << user
        
        render :update do |page|
          page.replace_html :presenters_to_save, :partial => 'presenters', :locals => {:users => users}
          page << "addTagsToList($('presenter_list_to_save'), #{user.id})" 
        end
      else
        return
      end
    else
      return
    end
  end
  
  def remove_presenter
    if request.post?
      if !params[:user_id].blank? and user = User.find_by_id(params[:user_id])
        params[:presenter_ids].blank? ? users = [user] : users = User.find(params[:presenter_ids].split(',').each{|pid| pid.to_i}).to_a - user
        
        render :update do |page|
          page.replace_html :presenters_to_save, :partial => 'presenters', :locals => {:users => users}
          #page << "addTagsToList($('presenter_list_to_save'), #{user.id})" 
        end
      else
        return
      end
    else
      return
    end
  end

end
