# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::FeedsController < ApplicationController
  skip_before_filter :login_required
  
  ENTRY_COUNT = 25
  DATE_EXPRESSION = "date_sub(curdate(), interval 7 day)"
  
  def expertise
    @category = Category.find_by_id(params[:id])
    if !@category
      @error_message = "Invalid category identifier"
      render_error
      return
    end
    @alternate_link = url_for(:controller => 'aae/search', :action => 'experts_by_category', :id => @category.id, :only_path => false)
    @users = @category.get_experts(:select => "users.*, expertise_areas.created_at as added_at", 
                                   :order => "expertise_areas.created_at desc", 
                                   :conditions => "expertise_areas.created_at > #{DATE_EXPRESSION}" )
    @updated_time = @users.any? ? @users.first.added_at.to_time : Time.new 

    headers["Content-Type"] = "application/xml"
  
    respond_to do |format|
      format.xml{render :template => 'aae/feeds/expertise', :layout => false}
    end
  end
  
  def incoming
    conditions_hash = list_view_feed
    
    if params[:id].nil?
      @feed_title = 'Incoming Ask an Expert Questions' + conditions_hash[:cumulative_title]
      @alternative_link = url_for(:controller => 'aae/incoming', :action => 'index', :location => params[:location], :county => params[:county], :source => params[:source], :only_path => false)  
      @submitted_questions = SubmittedQuestion.find(:all, :order => 'submitted_questions.created_at desc', :conditions => "submitted_questions.status_state = #{SubmittedQuestion::STATUS_SUBMITTED} and submitted_questions.created_at > #{DATE_EXPRESSION}" + conditions_hash[:cumulative_condition])
    elsif params[:id] == Category::UNASSIGNED
      @feed_title = 'Incoming Uncategorized Ask an Expert Questions' + conditions_hash[:cumulative_title]
      @alternative_link = url_for(:controller => 'aae/incoming', :action => 'index', :id => Category::UNASSIGNED, :location => params[:location], :county => params[:county], :source => params[:source], :only_path => false)  
      @submitted_questions = SubmittedQuestion.find_uncategorized(:all, :order => 'submitted_questions.created_at desc', :conditions => "submitted_questions.status_state = #{SubmittedQuestion::STATUS_SUBMITTED} and submitted_questions.created_at > #{DATE_EXPRESSION}" + conditions_hash[:cumulative_condition])
    else
      category = Category.find_by_name(params[:id])
      
      if !category
        category = Category.find_by_id(params[:id])
      end
      
      if !category
        @error_message = "Invalid category identifier"
        render_error
        return
      else
        @feed_title = "Incoming #{category.name} Ask an Expert Questions" + conditions_hash[:cumulative_title]
        @alternate_link = url_for(:controller => 'aae/incoming', :action => 'index', :id => category.name, :location => params[:location], :county => params[:county], :source => params[:source], :only_path => false)
        @submitted_questions = SubmittedQuestion.find_with_category(category, :all, :order => 'submitted_questions.created_at desc',
        :conditions => "submitted_questions.status_state = #{SubmittedQuestion::STATUS_SUBMITTED} and submitted_questions.created_at > #{DATE_EXPRESSION}" + conditions_hash[:cumulative_condition])
      end
    end
    
    render_submitted_questions
    
    rescue Exception => e
      @error_message = "Error loading your feed"
      render_error
      return 
  end
  
  def my_assigned
    user_id = params[:user_id]
    
    if !user_id or user_id.strip == ''
      @error_message = "Invalid User"
      render_error
      return
    end
    
    conditions_hash = list_view_feed
    
    if params[:id].nil?
      @feed_title = 'Ask an Expert Questions Assigned to Me' + conditions_hash[:cumulative_title]
      @alternative_link = url_for(:controller => 'aae/my_assigned', :action => :index, :location => params[:location], :county => params[:county], :source => params[:source], :only_path => false)  
      @submitted_questions = SubmittedQuestion.find(:all, :order => 'submitted_questions.created_at desc', :conditions => "submitted_questions.status_state = #{SubmittedQuestion::STATUS_SUBMITTED} and submitted_questions.user_id = #{user_id}" + conditions_hash[:cumulative_condition])
    elsif params[:id] == Category::UNASSIGNED
      @feed_title = 'Incoming Uncategorized Ask an Expert Questions Assigned to Me' + conditions_hash[:cumulative_title]
      @alternative_link = url_for(:controller => 'aae/my_assigned', :action => :index, :id => Category::UNASSIGNED, :location => params[:location], :county => params[:county], :source => params[:source], :only_path => false)  
      @submitted_questions = SubmittedQuestion.find_uncategorized(:all, :order => 'submitted_questions.created_at desc', :conditions => "submitted_questions.status_state = #{SubmittedQuestion::STATUS_SUBMITTED} and submitted_questions.user_id = #{user_id}" + conditions_hash[:cumulative_condition])
    else
      category = Category.find_by_name(params[:id])
      
      if !category
        category = Category.find_by_id(params[:id])
      end
      
      if !category
        @error_message = "Invalid category identifier"
        render_error
        return
      else
        @feed_title = "Incoming #{category.name} Ask an Expert Questions Assigned to Me" + conditions_hash[:cumulative_title]
        @alternate_link = url_for(:controller => 'aae/my_assigned', :action => :index, :id => category.name, :location => params[:location], :county => params[:county], :source => params[:source], :only_path => false)
        @submitted_questions = SubmittedQuestion.find_with_category(category, :all, :order => 'submitted_questions.created_at desc',
        :conditions => "submitted_questions.status_state = #{SubmittedQuestion::STATUS_SUBMITTED} and submitted_questions.user_id = #{user_id}" + conditions_hash[:cumulative_condition])
      end
    end
    
    render_submitted_questions
    
    rescue Exception => e
      logger.error(e.message)
      @error_message = "Error loading your feed"
      render_error
      return
  end
  
  def resolved
    @filterparams = FilterParams.new(params)
    if(!params[:id].nil?)
      @filterparams.legacycategory = params[:id]
    end
    
    filteroptions = {}
    filteroptions[:category] = @filterparams.legacycategory
    filteroptions[:county] = @filterparams.county
    filteroptions[:location] = @filterparams.location
    filteroptions[:source] = @filterparams.source
    # skip the joins because we are including them already with listdisplayincludes
    filteroptions[:skipjoins] = true
    
    linkoptions = {}
    linkoptions[:controller] = 'aae/resolved'
    linkoptions[:action] = :index
    linkoptions[:type] = params[:type]
    linkoptions[:category] = @filterparams.legacycategory
    linkoptions[:county] = (@filterparams.county.nil? ? nil : filterparams.county.id)
    linkoptions[:location] = (@filterparams.location.nil? ? nil : filterparams.location.id)
    linkoptions[:source] = @filterparams.source
    linkoptions[:only_path] = false
    
    case params[:type]
    when 'all'
      sq_query_method = 'resolved'
    when nil
      sq_query_method = 'resolved'
    when 'answered'
      sq_query_method = 'answered'
    when 'not_answered'
      sq_query_method = 'not_answered'
    when 'rejected'
      sq_query_method = 'rejected'
    else
      # raise an exception to be handled below
      raise
    end
    
    feed_title_text = (sq_query_method == 'resolved') ? '' : " / #{sq_query_method}"
    @feed_title = build_feed_title(@filterparams,feed_title_text)
    @alternative_link = url_for(linkoptions)  
    @submitted_questions = SubmittedQuestion.send(sq_query_method).filtered(filteroptions).ordered('submitted_questions.created_at desc').resolved_since(DATE_EXPRESSION).listdisplayincludes 
    
    render_submitted_questions
    
    # rescue Exception => e
    #   @error_message = "Error loading your feed"
    #   render_error
    #   return
  end
  
  def escalation
    cutoff_date = Time.new - (24 * 60 * 60 * 2) # two days
    
    if !params[:id]
      @feed_title = 'Escalated Ask an Expert Questions'
      @alternate_link = url_for(:controller => 'aae/question', :action => 'escalation_report', :only_path => false)
      @submitted_questions = SubmittedQuestion.find(:all, :conditions => ["status_state = #{SubmittedQuestion::STATUS_SUBMITTED} and created_at < ?", cutoff_date], :order => 'created_at desc')
    else
      category = Category.find_by_name(params[:id])
      
      if !category
        category = Category.find_by_id(params[:id])
      end
      
      if !category
        @error_message = "Invalid category identifier."
        render_error
        return
      else        
        @feed_title = "Escalated #{category.name} Ask an Expert Questions"
        @alternate_link = url_for(:controller => 'aae/incoming', :action => :index, :id => category.name, :only_path => false)

        @submitted_questions = category.submitted_questions.find(:all, :conditions => ["status_state = #{SubmittedQuestion::STATUS_SUBMITTED} and created_at < ?", cutoff_date], :order => 'created_at desc')
      end
      
    end
    
    render_submitted_questions    
  end
    
  private
  
  def build_feed_title(filterparams,additionaltitletext)
    
    if(filterparams.legacycategory.nil?)
      returntitle = "Resolved Ask an Expert Questions#{additionaltitletext}"
    elsif(filterparams.legacycategory.is_a?(String) and filterparams.legacycategory == Category::UNASSIGNED)
      returntitle = "Resolved Uncategorized Ask an Expert Questions#{additionaltitletext}"
    elsif(filterparams.legacycategory.is_a?(Category))
      returntitle = "Resolved#{additionaltitletext} #{filterparams.legacycategory.name} Ask an Expert Questions"
    else
      returntitle = "Resolved Ask an Expert Questions#{additionaltitletext}"
    end
      
    if(!filterparams.location.nil?)
      returntitle += " from the location #{filterparams.location.abbreviation}"
    end
    
    if(!filterparams.county.nil?)
      returntitle += " in #{filterparams.county.name} county"
    end
    
    if(!filterparams.source.nil?)
      case filterparams.source
      when 'pubsite'
        returntitle += " from source www.extension.org"
      when 'widget'
        returntitle += " from Ask eXtension widgets source"
      else
        source_int = filterparams.source.to_i
        if source_int != 0
          widget = Widget.find(:first, :conditions => "id = #{source_int}")
          returntitle += " from #{widget.name} widget source" if widget
        end
      end
    end
    
    return returntitle
  end
    
  
  def list_view_feed
    ret_hash = {}
    cumulative_condition = ''
    cumulative_title = ''
    
    if params[:location] and params[:location].strip != ''
      location = Location.find(params[:location])
      
      if !location
        @error_message = "Invalid location"
        render_error
        return
      else
        cumulative_condition += " and submitted_questions.location_id = #{params[:location]}"
        cumulative_title += " from the location #{location.abbreviation}"
      end
      
      if params[:county] and params[:county].strip != ''
        county = County.find(params[:county])
        
        if !county
          @error_message = "Invalid county"
          render_error
          return
        else
          cumulative_condition += " and submitted_questions.county_id = #{params[:county]}"
          cumulative_title += " in #{county.name} county"
        end
      end  
    end
    
    if params[:source] and params[:source].strip != ''
      case params[:source]
        when 'pubsite'
          cumulative_condition += " and submitted_questions.external_app_id != 'widget'"
          cumulative_title += " from source www.extension.org"
        when 'widget'
          cumulative_condition += " and submitted_questions.external_app_id = 'widget'"
          cumulative_title += " from Ask eXtension widgets source"
        else
          source_int = params[:source].to_i
          if source_int != 0
            widget = Widget.find(:first, :conditions => "id = #{source_int}")
          end

          if widget
            cumulative_condition += " and submitted_questions.widget_name = '#{widget.name}'"
            cumulative_title += " from #{widget.name} widget source"
          end
      end
    end
    
    ret_hash[:cumulative_condition] = cumulative_condition
    ret_hash[:cumulative_title] = cumulative_title
    
    return ret_hash
  end
  
  def render_submitted_questions
    headers["Content-Type"] = "application/xml"
    respond_to do |format|
      format.xml{render :template => 'aae/feeds/submitted_questions', :layout => false}
    end
  end
  
  def render_error
    headers["Content-Type"] = "application/xml"
    respond_to do |format|
      format.xml{render :template => 'aae/feeds/error', :layout => false}    
    end
  end
  
  def build_aae_conditions(custom_conditions, resolved_date_cutoff = nil)
    return_condition = ''
    
    if resolved_date_cutoff 
      return_condition << " and submitted_questions.resolved_at > #{resolved_date_cutoff}"
    end
    
    return_condition << custom_conditions if (custom_conditions and custom_conditions.strip != '')
    
    return return_condition
  end

  
end
