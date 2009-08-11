# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

#TODO: rewrite this.
class Aae::FeedsController < ApplicationController  
  ENTRY_COUNT = 25
  DATE_EXPRESSION = "date_sub(curdate(), interval 7 day)"
  
  def expertise
    @filterparams = FilterParams.new(params)
    if(@filterparams.legacycategory.nil?)
      @error_message = "Invalid category identifier"
      return render_error
    end
    
    @category = @filterparams.legacycategory

    @alternate_link = url_for(:controller => 'aae/search', :action => 'experts_by_category', :legacycategory => @category.id, :only_path => false)
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
    @filterparams = FilterParams.new(params)
    
    filteroptions = {}
    filteroptions[:category] = @filterparams.legacycategory
    filteroptions[:county] = @filterparams.county
    filteroptions[:location] = @filterparams.location
    filteroptions[:source] = @filterparams.source
    filteroptions[:assignee] = @filterparams.person
        
    linkoptions = {}
    linkoptions[:controller] = 'aae/incoming'
    linkoptions[:action] = :index
    linkoptions[:type] = params[:type]
    # TODO: this is still "id" over in the non feed views, need to change!
    linkoptions[:id] = @filterparams.legacycategory
    linkoptions[:county] = (@filterparams.county.nil? ? nil : @filterparams.county.id)
    linkoptions[:location] = (@filterparams.location.nil? ? nil : @filterparams.location.id)
    linkoptions[:source] = @filterparams.source
    linkoptions[:only_path] = false
    
    @feed_title = build_feed_title(@filterparams,"Incoming",'')
    @alternate_link = url_for(linkoptions)  
    
    @submitted_questions = SubmittedQuestion.submitted.filtered(filteroptions).ordered('submitted_questions.created_at desc').created_since(DATE_EXPRESSION).listdisplayincludes 
    
  
    render_submitted_questions
    
    rescue Exception => e
      logger.error(e.message)
      @error_message = "Error loading your feed"
      render_error
      return
  end
  
  def my_assigned
    @filterparams = FilterParams.new(params)
    if(@filterparams.person.nil?)
      # check for use of 'user_id' param
      if(!params[:user_id].nil?)
        @filterparams.person = params[:user_id]
      end
    end
    
    if(@filterparams.person.nil?)
      @error_message = "Invalid account specified"
      return render_error
    end
    
    filteroptions = {}
    filteroptions[:category] = @filterparams.legacycategory
    filteroptions[:county] = @filterparams.county
    filteroptions[:location] = @filterparams.location
    filteroptions[:source] = @filterparams.source
    filteroptions[:assignee] = @filterparams.person
    
    linkoptions = {}
    linkoptions[:controller] = 'aae/my_assigned'
    linkoptions[:action] = :index
    linkoptions[:type] = params[:type]
    # TODO: this is still "id" over in the non feed views, need to change!
    linkoptions[:id] = @filterparams.legacycategory
    linkoptions[:county] = (@filterparams.county.nil? ? nil : @filterparams.county.id)
    linkoptions[:location] = (@filterparams.location.nil? ? nil : @filterparams.location.id)
    linkoptions[:source] = @filterparams.source
    # TODO: this is still "user_id" over in the non feed views, need to change!
    linkoptions[:user_id] = @filterparams.person.id
    linkoptions[:only_path] = false
    
    @feed_title = build_feed_title(@filterparams,"Assigned to #{@filterparams.person.fullname}",'')
    @alternate_link = url_for(linkoptions)  
    
    @submitted_questions = SubmittedQuestion.submitted.filtered(filteroptions).ordered('submitted_questions.created_at desc').listdisplayincludes 
    
  
    render_submitted_questions
    
    rescue Exception => e
      logger.error(e.message)
      @error_message = "Error loading your feed"
      render_error
      return
  end
  
  def resolved
    @filterparams = FilterParams.new(params)
    
    filteroptions = {}
    filteroptions[:category] = @filterparams.legacycategory
    filteroptions[:county] = @filterparams.county
    filteroptions[:location] = @filterparams.location
    filteroptions[:source] = @filterparams.source
    
    linkoptions = {}
    linkoptions[:controller] = 'aae/resolved'
    linkoptions[:action] = :index
    linkoptions[:type] = params[:type]
    # note, this is still "id" over in the non feed views, need to change!
    linkoptions[:id] = @filterparams.legacycategory
    linkoptions[:county] = (@filterparams.county.nil? ? nil : @filterparams.county.id)
    linkoptions[:location] = (@filterparams.location.nil? ? nil : @filterparams.location.id)
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
    
    feed_title_text = (sq_query_method == 'resolved') ? '' : "/ #{sq_query_method}"
    @feed_title = build_feed_title(@filterparams,'Resolved',feed_title_text)
    @alternate_link = url_for(linkoptions)  
    @submitted_questions = SubmittedQuestion.send(sq_query_method).filtered(filteroptions).ordered('submitted_questions.created_at desc').resolved_since(DATE_EXPRESSION).listdisplayincludes 
    
    render_submitted_questions
    
    rescue Exception => e
      @error_message = "Error loading your feed"
      render_error
      return
  end
  
  def escalation
    @filterparams = FilterParams.new(params)
    sincehours = AppConfig.configtable['aae_escalation_delta'] = 24
    
    linkoptions = {}
    linkoptions[:controller] = 'aae/question'
    linkoptions[:action] = :escalation_report
    linkoptions[:legacycategory] = @filterparams.legacycategory
    linkoptions[:only_path] = false
    
    if(!@filterparams.legacycategory.nil?)
      if(@filterparams.legacycategory.is_a?(Category))
        @feed_title = "Escalated #{@filterparams.legacycategory.name} Ask an Expert Questions"
      elsif(@filterparams.legacycategory.is_a?(String) and @filterparams.legacycategory == Category::UNASSIGNED)
        @feed_title = "Escalated Uncategorized Ask an Expert Questions"
      else
        @feed_title = 'Escalated Ask an Expert Questions'
      end
    else
      @feed_title = 'Escalated Ask an Expert Questions'
    end
    
    @alternate_link = url_for(linkoptions)  
    @submitted_questions = SubmittedQuestion.escalated(sincehours).filtered({:category => @filterparams.legacycategory}).listdisplayincludes.ordered('submitted_questions.created_at desc')
    render_submitted_questions    
  end
    
  private
  
  def build_feed_title(filterparams,label,additionaltitletext)
    
    if(filterparams.legacycategory.nil?)
      returntitle = "#{label} Ask an Expert Questions #{additionaltitletext}"
    elsif(filterparams.legacycategory.is_a?(String) and filterparams.legacycategory == Category::UNASSIGNED)
      returntitle = "#{label} Uncategorized Ask an Expert Questions #{additionaltitletext}"
    elsif(filterparams.legacycategory.is_a?(Category))
      returntitle = "#{label} #{additionaltitletext} #{filterparams.legacycategory.name} Ask an Expert Questions"
    else
      returntitle = "#{label} Ask an Expert Questions #{additionaltitletext}"
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
