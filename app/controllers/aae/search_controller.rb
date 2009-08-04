# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::SearchController < ApplicationController
  layout 'aae'
  before_filter :filter_string_helper
  before_filter :login_required
  
  def index
    @aae_search_item = SearchQuestion.find_by_entrytype_and_foreignid(params[:type], params[:qid])
    if !@aae_search_item
      flash[:failure] = "Invalid question parameters"
      redirect_to incoming_url
      return
    end
    
    @aae_search_item.entrytype == SearchQuestion::AAE ? @type = 'Ask an Expert Question' : @type = 'FAQ'
  end
  
  def answer
    @aae_search_item = SearchQuestion.find(params[:id])
    @submitted_question = SubmittedQuestion.find(params[:squid])
    @aae_search_item.entrytype == SearchQuestion::AAE ? @type = 'Ask an Expert Question' : @type = 'FAQ'
  
    if !(@aae_search_item and @submitted_question)
      flash[:failure] = "Invalid input"
      redirect_to incoming_url
      return
    end
  end
  
  def enable_search_by_name
    @submitted_question = SubmittedQuestion.find_by_id(params[:id])
    render :layout => false
  end
  
  def enable_search_by_cat_loc
    @submitted_question = SubmittedQuestion.find(:first, :conditions => ["id = ?", params[:id]])
    @category = @submitted_question.categories.find(:first, :conditions => "categories.parent_id IS NULL")
    @location = @submitted_question.location
    @county = @submitted_question.county
    setup_cat_loc
    
    render :layout => false
  end
  
  def answers
    if params[:squid] and @submitted_question = SubmittedQuestion.find_by_id(params[:squid])    
      if params[:q] and params[:q].strip != ''
        @aae_search_results = SearchQuestion.full_text_search({:q => params[:q]}).all(:order => 'match_score', :limit => 30)
      else
        flash[:failure] = "You must enter valid text into the search field." 
        redirect_to aae_question_url(:id => @submitted_question.id)
        return
      end
    else
      flash[:failure] = "The question specified does not exist."
      redirect_to incoming_url
      return
    end
  end
  
  def assignees_by_cat_loc
    @category = Category.find(:first, :conditions => ["id = ?", params[:category]]) if params[:category] and params[:category].strip != ''
    @location = ExpertiseLocation.find(:first, :conditions => ["fipsid = ?", params[:location]]) if params[:location] and params[:location].strip != ''
    @county = ExpertiseCounty.find(:first, :conditions => ["fipsid = ? and state_fipsid = ?", params[:county], @location.fipsid]) if @location and params[:county] and params[:county].strip != ''
    
    setup_cat_loc
    render :partial => "search_expert", :layout => false
  end
  
  def assignees_by_name
    #if a login/name was typed into the field to search for users
    login_str = params[:login]
    if !login_str or login_str.strip == ""
      render :nothing => true
      return
    end
    
    #split on comma delimited or space delimited input
    #examples of possibilities of input include:
    #lastname,firstname
    #lastname, firstname
    #lastname firstname
    #firstname,lastname
    #firstname lastname
    #loginid
    user_name = login_str.strip.split(%r{\s*,\s*|\s+})
    
    #if comma or space delimited...
    if user_name.length > 1
      @users = User.find(:all, :include => [:expertise_locations, :open_questions, :categories], :limit => 20, :conditions => ['((first_name like ? and last_name like ?) or (last_name like ? and first_name like ?)) and users.retired = false', user_name[0] + '%', user_name[1] + '%', user_name[0] + '%', user_name[1] + '%'], :order => 'first_name')
    #else only a single word was typed
    else
      @users = User.find(:all, :include => [:expertise_locations, :open_questions, :categories], :limit => 20, :conditions => ['(login like ? or first_name like ? or last_name like ?) and users.retired = false', user_name[0] + '%', user_name[0] + '%', user_name[0] + '%'], :order => 'first_name')
    end
    
    render :template => 'ask/expert/assignees_by_name.js.rjs', :layout => false
    
  end
  
end