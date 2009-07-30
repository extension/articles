# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Ask::FeedsController < ApplicationController
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
    @alternate_link = url_for(:controller => 'ask/expert', :action => 'category', :id => @category.id, :only_path => false)
    @users = @category.get_experts(:select => "users.*, expertise_areas.created_at as added_at", 
                                   :order => "expertise_areas.created_at desc", 
                                   :conditions => "expertise_areas.created_at > #{DATE_EXPRESSION}" )
    @updated_time = @users.any? ? @users.first.added_at.to_time : Time.new 

    headers["Content-Type"] = "application/xml"
  
    respond_to do |format|
      format.xml{render :template => 'ask/feeds/expertise', :layout => false}
    end
  end
  
  def incoming
    conditions_hash = list_view_feed
    
    if params[:id].nil?
      @feed_title = 'Incoming Ask an Expert Questions' + conditions_hash[:cumulative_title]
      @alternative_link = url_for(:controller => 'expert', :action => 'incoming', :location => params[:location], :county => params[:county], :source => params[:source], :only_path => false)  
      @submitted_questions = SubmittedQuestion.find(:all, :order => 'submitted_questions.created_at desc', :conditions => "submitted_questions.status_state = #{SubmittedQuestion::STATUS_SUBMITTED} and submitted_questions.created_at > #{DATE_EXPRESSION}" + conditions_hash[:cumulative_condition])
    elsif params[:id] == Category::UNASSIGNED
      @feed_title = 'Incoming Uncategorized Ask an Expert Questions' + conditions_hash[:cumulative_title]
      @alternative_link = url_for(:controller => 'expert', :action => 'incoming', :id => Category::UNASSIGNED, :location => params[:location], :county => params[:county], :source => params[:source], :only_path => false)  
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
        @alternate_link = url_for(:controller => 'expert', :action => 'incoming', :id => category.name, :location => params[:location], :county => params[:county], :source => params[:source], :only_path => false)
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
      @alternative_link = url_for(:controller => 'expert', :action => 'assigned', :location => params[:location], :county => params[:county], :source => params[:source], :only_path => false)  
      @submitted_questions = SubmittedQuestion.find(:all, :order => 'submitted_questions.created_at desc', :conditions => "submitted_questions.status_state = #{SubmittedQuestion::STATUS_SUBMITTED} and submitted_questions.user_id = #{user_id}" + conditions_hash[:cumulative_condition])
    elsif params[:id] == Category::UNASSIGNED
      @feed_title = 'Incoming Uncategorized Ask an Expert Questions Assigned to Me' + conditions_hash[:cumulative_title]
      @alternative_link = url_for(:controller => 'expert', :action => 'assigned', :id => Category::UNASSIGNED, :location => params[:location], :county => params[:county], :source => params[:source], :only_path => false)  
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
        @alternate_link = url_for(:controller => 'expert', :action => 'assigned', :id => category.name, :location => params[:location], :county => params[:county], :source => params[:source], :only_path => false)
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
    conditions_hash = list_view_feed
    
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
    
    if params[:id].nil?
      @feed_title = "Resolved Ask an Expert Questions#{feed_title_text}" + conditions_hash[:cumulative_title]
      @alternative_link = url_for(:controller => 'expert', :action => 'resolved', :location => params[:location], :county => params[:county], :source => params[:source], :type => params[:type], :only_path => false)  
      conditions_string = build_aae_conditions(conditions_hash[:cumulative_condition], DATE_EXPRESSION)    
      @submitted_questions = SubmittedQuestion.send(sq_query_method, [], conditions_string).by_order
    elsif params[:id] == Category::UNASSIGNED
      @feed_title = "Resolved Uncategorized Ask an Expert Questions#{feed_title_text}" + conditions_hash[:cumulative_title]
      @alternative_link = url_for(:controller => 'expert', :action => 'resolved', :id => Category::UNASSIGNED, :location => params[:location], :county => params[:county], :source => params[:source], :type => params[:type], :only_path => false)  
      conditions_string = build_aae_conditions(conditions_hash[:cumulative_condition] + " and categories.id IS NULL", DATE_EXPRESSION)
      @submitted_questions = SubmittedQuestion.send(sq_query_method, [:categories], conditions_string).by_order
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
        @feed_title = "Resolved#{feed_title_text} #{category.name} Ask an Expert Questions" + conditions_hash[:cumulative_title]
        @alternate_link = url_for(:controller => 'expert', :action => 'resolved', :id => category.name, :location => params[:location], :county => params[:county], :source => params[:source], :type => params[:type], :only_path => false)
        conditions_string = build_aae_conditions(conditions_hash[:cumulative_condition] + " and (categories.id = #{category.id} or categories.parent_id = #{category.id})", DATE_EXPRESSION)
        @submitted_questions = SubmittedQuestion.send(sq_query_method, [:categories], conditions_string).by_order
      end
    end
    
    render_submitted_questions
    
    rescue Exception => e
      @error_message = "Error loading your feed"
      render_error
      return
  end
  
  def escalation
    cutoff_date = Time.new - (24 * 60 * 60 * 2) # two days
    
    if !params[:id]
      @feed_title = 'Escalated Ask an Expert Questions'
      @alternate_link = url_for(:controller => 'expert', :action => 'escalation_report', :only_path => false)
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
        @alternate_link = url_for(:controller => 'expert', :action => 'incoming', :id => category.name, :only_path => false)

        @submitted_questions = category.submitted_questions.find(:all, :conditions => ["status_state = #{SubmittedQuestion::STATUS_SUBMITTED} and created_at < ?", cutoff_date], :order => 'created_at desc')
      end
      
    end
    
    render_submitted_questions    
  end
    
  private
  
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
      format.xml{render :template => 'ask/feeds/submitted_questions', :layout => false}
    end
  end
  
  def render_error
    headers["Content-Type"] = "application/xml"
    respond_to do |format|
      format.xml{render :template => 'ask/feeds/error', :layout => false}    
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
