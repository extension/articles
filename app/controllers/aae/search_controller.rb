# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::SearchController < ApplicationController
  layout 'aae'
  before_filter :login_required, :except => [:get_counties]
  before_filter :check_purgatory, :except => [:get_counties]  
  
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
    @location = ExpertiseLocation.find_by_fipsid(@submitted_question.location.fipsid) if @submitted_question.location
    @county = ExpertiseCounty.find_by_fipsid(@submitted_question.county.fipsid) if @submitted_question.county
    setup_cat_loc
    render :layout => false
  end
  
  def general_search
    if params[:q] and params[:q].strip != ''
       # if someone put in a number (id) to search on
        if params[:q] =~ /^[0-9]+$/
          @aae_search_results = SearchQuestion.aae_questions.find_all_by_foreignid(params[:q]).paginate(:page => params[:page]) 
          return
        end
        
        formatted_search_terms = format_full_text_search_terms(params[:q])
        @aae_search_results = SearchQuestion.full_text_search({:q => formatted_search_terms, :boolean_mode => true}).aae_questions.all(:order => 'match_score desc').paginate(:page => params[:page])        
    else
      flash[:failure] = "You must enter valid text into the search field." 
      request.env["HTTP_REFERER"] ? (redirect_to :back) : (redirect_to incoming_url)
      return
    end      
  end
  
  def answers
    setup_aae_search_params
    if params[:squid] and @submitted_question = SubmittedQuestion.find_by_id(params[:squid])    
      if params[:q] and params[:q].strip != ''
        
        # if someone put in a number (id) to search on
        if params[:q] =~ /^[0-9]+$/
          
          if session[:aae_search] == ['faq']
            @aae_search_results = SearchQuestion.faq_questions.find_all_by_foreignid(params[:q])
          elsif session[:aae_search] == ['aae']
            @aae_search_results = SearchQuestion.aae_questions.find_all_by_foreignid(params[:q])
          else
            @aae_search_results = SearchQuestion.find_all_by_foreignid(params[:q])
          end
          
          return
        end
        
        formatted_search_terms = format_full_text_search_terms(params[:q])
        
        if session[:aae_search] == ['faq']
          @aae_search_results = SearchQuestion.full_text_search({:q => formatted_search_terms, :boolean_mode => true}).faq_questions.all(:order => 'match_score desc', :limit => 30)
        elsif session[:aae_search] == ['aae']
          @aae_search_results = SearchQuestion.full_text_search({:q => formatted_search_terms, :boolean_mode => true}).aae_questions.all(:order => 'match_score desc', :limit => 30)
        else
          @aae_search_results = SearchQuestion.full_text_search({:q => formatted_search_terms, :boolean_mode => true}).all(:order => 'match_score desc', :limit => 30)
        end
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
    
    if(params[:show_label] and params[:show_label] = 'yes')
      @show_label = true
    else
      @show_label = false
    end
    
    render :layout => false
  end
  
  ## with both assigness_by_cat_loc and assignees_by_name, profile attributes like handling counts and other profile information
  # are pulled and prepopulated for the jquery based tooltips so that the tooltips will already be populated when 
  # the assignee mouses over their name. to speed up the initial loading of all the experts, 
  # we have put a limit on the amount of experts returned and have enabled pagination on it. 
  
  def assignees_by_cat_loc
    @category = Category.find(:first, :conditions => ["id = ?", params[:category]]) if params[:category] and params[:category].strip != ''
    @location = ExpertiseLocation.find(:first, :conditions => ["fipsid = ?", params[:location]]) if params[:location] and params[:location].strip != ''
    @county = ExpertiseCounty.find(:first, :conditions => ["fipsid = ? and state_fipsid = ?", params[:county], @location.fipsid]) if @location and params[:county] and params[:county].strip != ''
    setup_cat_loc # sets @users
    # gets aae question handling counts for all experts returned
    @handling_counts = User.aae_handling_event_count({:group_by_id => true, :limit_to_handler_ids => @users.map(&:id), :submitted_question_filter => {:notrejected => true}})
    render :partial => "search_expert", :layout => false
  end
  
  def assignees_by_name
    #if a login/name was typed into the field to search for users
    login_str = params[:login]
    if !login_str or login_str.strip == ""
      render :nothing => true
      return
    end
    
    @users = User.notsystem.validusers.patternsearch(params[:login]).all(:limit => User.per_page, :include => [:expertise_locations, :open_questions, :categories])
    # gets aae question handling counts for all experts returned
    @handling_counts = User.aae_handling_event_count({:group_by_id => true, :limit_to_handler_ids => @users.map(&:id),:submitted_question_filter => {:notrejected => true}})  
    render :template => 'aae/search/assignees_by_name.js.rjs', :layout => false
  end
    
  def get_more_experts_by_cat_loc
    page_number = params[:page_number].to_i
    category = Category.find(params[:category_id]) if !params[:category_id].blank?
    location = Location.find(params[:location_id]) if !params[:location_id].blank?
    county = County.find(params[:county_id]) if !params[:county_id].blank?
    
    user_total = User.count_by_cat_loc(category, location, county)
    
    if (page_number * User.per_page) >= user_total
      more_experts_to_come = false
    else
      more_experts_to_come = true
    end
    
    users = User.find_by_cat_loc(category, location, county, page_number)
    handling_counts = User.aae_handling_event_count({:group_by_id => true, :limit_to_handler_ids => users.map(&:id), :submitted_question_filter => {:notrejected => true}})
  
    render(:update) do |page| 
      page.insert_html :bottom, :more_experts, :partial => 'expert_profiles', :locals => {:users => users, :handling_counts => handling_counts}
      page.replace_html :more_experts_link, :partial => 'more_experts_link', :locals => {:more_experts_to_come => more_experts_to_come, :category => category ? category : nil, :location => location ? location : nil, :county => county ? county : nil, :page_number => page_number + 1}
    end
  end
  
  private
  
  def get_answering_users(selected_users)
    user_ids = selected_users.map{|u| u.id}.join(',')
    answering_role = Role.find_by_name(Role::AUTO_ROUTE)
    user_intersection = answering_role.users.find(:all, :select => "accounts.*", :conditions => "accounts.id IN (#{user_ids})")
  end
  
  def setup_aae_search_params
    session[:aae_search] = []
    if !params[:faq_search] and !params[:aae_search]
      session[:aae_search] = ['faq', 'aae']
    else
      session[:aae_search] << 'faq' if params[:faq_search]
      session[:aae_search] << 'aae' if params[:aae_search]
    end
  end
  
  # get instance variables ready for expert search by category and location
  def setup_cat_loc
    @location_options = [""].concat(ExpertiseLocation.find(:all, :order => 'entrytype, name').map{|l| [l.name, l.fipsid]})
    @categories = Category.root_categories.all(:order => 'name')
    @category_options = @categories.map{|c| [c.name,c.id]}
    
    @county_fips = @county.fipsid if @county  
    @category_id = @category.id if @category
    @location_fips = @location.fipsid if @location
    
    # ToDo: need to change this id parameter name to something more descriptive
    @submitted_question = SubmittedQuestion.find(:first, :conditions => ["id = ?", params[:id]]) if not @submitted_question
    
    # What we're doing here is getting a total count of the users in said category, location, and county
    # when the expert search is executing. The reason we want this is because we now have custom 
    # pagination when searching for experts for efficiency so we're dumping hundreds of records out 
    # on search for experts. The link in the expert search that triggers the custom pagination is 
    # the show more matching experts link at the bottom of the returned search results. 
    user_total = User.count_by_cat_loc(@category, @location, @county)
  
    # determine whether we should display the shore more matching experts link 
    if User.per_page >= user_total
      @more_experts_to_come = false
    else
      @more_experts_to_come = true
    end
    
    # searh users by category, location, and county. since this function is used 
    # when the expert search is being populated for the first time, we pull page 1.
    @users = User.find_by_cat_loc(@category, @location, @county, 1)
  end
    
  def format_full_text_search_terms(search_string, search_option = '+')
    search_array = Array.new
    search_string = search_string.strip.downcase
    
    if search_string != ''
      quote_count = search_string.count('"')
      # check to see if quotes exist in in the search string and 
      # if they do, then make sure that they are paired up.
      if (quote_count > 0) and (quote_count % 2 == 0)
        start_quote = 0
        end_quote = 0
        # loop through the string finding pairs of quotes and removing quoted strings 
        # and adding them to the search array
        while search_string.include?('"') and (start_quote and end_quote)
          # reset quote positions each time the loop executes
          start_quote = 0
          end_quote = 0
          start_quote = search_string.index('"', start_quote)        
          end_quote = search_string.index('"', start_quote + 1)
          # remove section in between quotes and the quotes as well
          quoted_str = search_string.slice!(start_quote..end_quote)
          search_array << search_option + quoted_str if (start_quote and end_quote and ((quoted_str.length - 2) > 2))
        end
      end
      
      if search_string.include?(',')
        search_array.concat(get_search_term_inflections(search_option, search_string.split(',')))
      else
        search_array.concat(get_search_term_inflections(search_option, search_string.split(' ')))
      end
      
    else
      return ''
    end
    
    return search_array.join(' ')
      
  end
  
  def get_search_term_inflections(search_option, search_term_array)
    ret_array = Array.new
    # filter out all duplicate search terms and strip of whitespace on the ends
    search_term_array = search_term_array.uniq.collect{|s| s.strip}
    # filter out all MySQL stopwords
    search_term_array = search_term_array - SearchConstants::STOP_WORDS
    
    search_term_array.each do |search_term|
      # do not consider words less than 3 characters long
      if search_term.length < 3
        next
      end
      # add singular and plural forms of the search term
      # note the 'search_option' gets added too (which for boolean searches are '+' for required ANDed searches)
      search_term == ActiveSupport::Inflector.pluralize(search_term) ? inflection_str = ActiveSupport::Inflector.singularize(search_term) : inflection_str = ActiveSupport::Inflector.pluralize(search_term)
      ret_array << search_option + "(#{search_term} #{inflection_str})"
    end
    ret_array
  end
  
end