# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::SearchController < ApplicationController
  layout 'aae'
  before_filter :filter_string_helper
  before_filter :login_required, :except => [:get_counties]
  
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
  
  def get_counties
    if !params[:location_id] or params[:location_id].strip == '' or !(location = Location.find_by_id(params[:location_id]))
      @counties = nil
    else
      @counties = location.counties.find(:all, :order => 'name', :conditions => "countycode <> '0'")
    end
    
    render :layout => false
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
    
    render :template => 'aae/search/assignees_by_name.js.rjs', :layout => false
    
  end
  
  def experts_by_location
    if params[:id]
      @location = ExpertiseLocation.find(:first, :conditions => ["fipsid = ?", params[:id].to_i])
      if !@location
        flash[:failure] = "Invalid Location Entered"
        redirect_to incoming_url
      else
        @users = @location.users.find(:all, :order => "users.first_name")
      end
    else
      flash[:failure] = "Invalid Location Entered"
      redirect_to incoming_url
    end
  end
  
  def experts_by_category
    #if all users with an expertise in a category were selected
    if (!params[:legacycategory].nil? and @category = Category.find_by_name_or_id(params[:legacycategory]))
      @category_name = @category.name
      @users = @category.users
      @combined_users = get_answering_users(@users) if @users.length > 0
    else
      flash[:failure] = "Invalid Category"
      request.env["HTTP_REFERER"] ? (redirect_to :back) : (redirect_to incoming_url)
      return
    end
  end
  
  private
  
  def get_answering_users(selected_users)
    user_ids = selected_users.map{|u| u.id}.join(',')
    answering_role = Role.find_by_name(Role::AUTO_ROUTE)
    answering_users = answering_role.users.find(:all, :select => "users.*", :conditions => "users.id IN (#{user_ids})")
    user_intersection = selected_users & answering_users
  end
  
  def setup_cat_loc
    @location_options = [""].concat(ExpertiseLocation.find(:all, :order => 'entrytype, name').map{|l| [l.name, l.fipsid]})
    @categories = Category.root_categories
    @category_options = @categories.map{|c| [c.name,c.id]}
    
    @county_fips = @county.fipsid if @county  
    @category_id = @category.id if @category
    @location_fips = @location.fipsid if @location
    
    # ToDo: need to change this id parameter name to something more descriptive
    @submitted_question = SubmittedQuestion.find(:first, :conditions => ["id = ?", params[:id]]) if not @submitted_question
    @users = User.find_by_cat_loc(@category, @location, @county)
  end
  
end