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
      
      if !@learn_session.valid?
        render :template => '/learn/create_session'
        return
      else
        @learn_session.save
        flash.now[:success] = "Learning lesson saved successfully!<br />Thank you for your submission!"
        render :template => '/learn/create_session'
      end
    # GET request for initial form display
    else
      learn_session = LearnSession.new    
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
        render :update do |page|
          page.insert_html :bottom, :presenters_to_save, :partial => 'presenter', :locals => {:user => user}
          page.call 'addTagsToList', page[:presenter_list_to_save], user.id 
        end
      else
        return
      end
    else
      return
    end
  end

end
