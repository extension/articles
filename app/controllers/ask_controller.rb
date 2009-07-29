class AskController < ApplicationController
  
  skip_before_filter :login_required
  has_rakismet :only => [:submit_question]
  
  def index
    @right_column = false
    session[:return_to] = params[:redirect_to]
    flash.now[:googleanalytics] = '/ask-an-expert-form'
    
    set_title("Ask an Expert - eXtension", "New Question")
    set_titletag("Ask an Expert - eXtension")

    # if we are editing
    if params[:submitted_question]
      flash.now[:googleanalytics] = '/ask-an-expert-edit-question'
      set_titletag("Edit your Question - eXtension")
      begin
        @submitted_question = SubmittedQuestion.new(params[:submitted_question])
        @submitted_question.location_id = params[:location_id]
        @submitted_question.county_id = params[:county_id]
        @submitted_question.setup_categories(params[:aae_category], params[:subcategory])
        @top_level_category = @submitted_question.top_level_category if @submitted_question.top_level_category
        @sub_category = @submitted_question.sub_category.id if @submitted_question.sub_category
        
        if @top_level_category 
          @sub_category_options = [""].concat(@top_level_category.children.map{|sq| [sq.name, sq.id]})
        else
          @sub_category_options = [""]
        end
        # run validator to display any input errors
        @submitted_question.valid?
      rescue
        @submitted_question = SubmittedQuestion.new
      end
    else
      # not sure yet if we'll be using the 'new_from_personal' method
      #@submitted_question = SubmittedQuestion.new_from_personal(@personal)      
      @submitted_question = SubmittedQuestion.new
    end
    
    @location_options = get_location_options
    @county_options = get_county_options
    
    @categories = [""].concat(Category.launched_content_categories.map{|c| [c.name, c.id]})
  end
  
  def question_confirmation
    params[:submitted_question][:asked_question] = params[:q]
    flash.now[:googleanalytics] = '/ask-an-expert-search-results'
    set_title("Ask an Expert - eXtension", "Confirmation")
    set_titletag("Search Results for Ask an Expert - eXtension")
    
    @submitted_question = SubmittedQuestion.new(params[:submitted_question])
    
    unless @submitted_question.valid?
      redirect_to :action => 'index', 
                  :submitted_question => params[:submitted_question], 
                  :location_id => params[:location_id], 
                  :county_id => params[:county_id], 
                  :aae_category => params[:aae_category], 
                  :subcategory => params[:subcategory]
    end
  end
  
  def submit_question
    @submitted_question = SubmittedQuestion.new(params[:submitted_question])
    @submitted_question.location_id = params[:location_id]
    @submitted_question.county_id = params[:county_id]
    @submitted_question.setup_categories(params[:aae_category], params[:subcategory])
    @submitted_question.status = 'submitted'
    @submitted_question.user_ip = request.remote_ip
    @submitted_question.user_agent = request.env['HTTP_USER_AGENT']
    @submitted_question.referrer = request.env['HTTP_REFERER']
    @submitted_question.spam = @submitted_question.spam?
    @submitted_question.status_state = SubmittedQuestion::STATUS_SUBMITTED
    @submitted_question.status = SubmittedQuestion::SUBMITTED_TEXT
    @submitted_question.external_app_id = 'www.extension.org'
    
    if !@submitted_question.valid? || !@submitted_question.save
      flash[:notice] = 'There was an error saving your question. Please try again.'
      redirect_to :action => 'index'
      return
    end
    
    flash[:notice] = 'Your question has been submitted and the answer will be sent to your email. Our experts try to answer within 48 hours.'
    flash[:googleanalytics] = '/ask-an-expert-question-submitted'
    if session[:return_to]
      redirect_to(session[:return_to]) 
    else
      redirect_to '/'
    end
  end
  
  def get_aae_form_subcats
    parent_cat = Category.find_by_id(params[:category_id].strip) if params[:category_id] and params[:category_id].strip != '' 
    if parent_cat 
      @sub_category_options = [""].concat(parent_cat.children.map{|sq| [sq.name, sq.id]})
    else
      @sub_category_options = [""]
    end
    
    render :partial => 'aae_subcats', :layout => false
  end
  
  
end
