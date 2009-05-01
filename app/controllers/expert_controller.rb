# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
require 'zip_code_to_state'
class ExpertController < DataController
  
  include Akismet
  
  def index
    redirect_to :action => 'ask_an_expert'
  end
  
  def ask_an_expert
    session[:return_to] = params[:redirect_to]
    flash.now[:googleanalytics] = '/ask-an-expert-form'
    
    set_title("Ask an Expert - eXtension", "New Question")
    set_titletag("Ask an Expert - eXtension")

    # if we are editing
    if params[:expert_question]
      flash.now[:googleanalytics] = '/ask-an-expert-edit-question'
      set_titletag("Edit your Question - eXtension")
      begin
        @expert_question = ExpertQuestion.new(params[:expert_question])
      rescue
        @expert_question = ExpertQuestion.new
      end
      @expert_question.valid?      
    else
      @expert_question = ExpertQuestion.new_from_personal(@personal)      
    end
    @community_tags = Community.visible_tags
    @community_tags.insert(0, ["", ""])
    
    @locations = Location.find(:all)
  end
  
  def get_subtags
    return render( :text => '', :layout => false) if params[:category_name] == ''
    expert_question = ExpertQuestion.new(:category_name => params[:category_name])
    return render( :text => '', :layout => false) if ! expert_question.category_tag or expert_question.category_tag.sub_tags.length == 0
    render :partial => "select_sub_tag", :locals => {:expert_question => expert_question, :disabled => false}
  end
  
  def get_counties
    return render( :nothing => true) if !params[:location_id] or params[:location_id].strip == ''
    render(:partial => 'county_list', :locals => {:location=> Location.find(params[:location_id]), :disabled => false} )
    #render :partial => "county_list", :layout => false
  end
  
  def question_confirmation
    #q must be used for google to recognize
    if !params[:q] or params[:q].strip == '' || !params[:expert_question]
      flash[:notice] = "You must enter valid text into the question field."
      return redirect_to( {:action => 'ask_an_expert'}.update( flatten_hash_for_url( {:expert_question => params[:expert_question]} ) ))
    end
    params[:expert_question][:asked_question] = params[:q]
    flash.now[:googleanalytics] = '/ask-an-expert-search-results'
    set_title("Ask an Expert - eXtension", "Confirmation")
    set_titletag("Search Results for Ask an Expert - eXtension")
    
    
    #get top level category if it exists 
    if params[:category_id] and params[:category_id].strip.length > 0
      @category = Category.find_by_id(params[:category_id])
      #get subcategory if it exists
      if params[:subcategory_id] and params[:subcategory_id].strip.length > 0
        @subcategory = Subcategory.find_by_id(params[:subcategory_id])
      end
    end
    
    @expert_question = ExpertQuestion.new(params[:expert_question])
    @expert_question.status = 'submitted'
    @flattened_eq_parameters = flatten_hash_for_url( {:expert_question => params[:expert_question]} )
    unless @expert_question.valid?
      return redirect_to( {:action => 'ask_an_expert'}.update( @flattened_eq_parameters ))
    end

    formatted_question = params[:q].strip.upcase
    
    if ExpertQuestion.find(:first, :conditions => ["submitted_by = ? and (UCase(trim(asked_question)) = trim(?))", session[:user_id], formatted_question])
      flash[:notice] = "Our records indicate that you have already submitted this question.<br />Please do not submit a question more than once."
      redirect_to :action => 'ask_an_expert', :category_id => params[:category_id], :subcategory_id => params[:subcategory_id],
      :location_selected => params[:location_option], :county_selected => params[:county_option], :question => params[:q]
      return
    end

    
  end
  
  def submit_question
    @expert_question = ExpertQuestion.new(params[:expert_question])
    #@expert_question.submitted_by = current_user.id if logged_in?
    @expert_question.status = 'submitted'
    @expert_question.spam = false
    @expert_question.app_string = request.host
    
    
    if !@expert_question.valid? || !@expert_question.save
      flash[:notice] = 'There was an error saving your question. Please try again.'
      redirect_to :action => 'ask_an_expert'
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
  
  #view the questions that the current user has asked
  def view_questions
     @user_questions = ExpertQuestion.find(:all, :conditions => ["submitted_by = ?", @user.id], :order => 'has_read, created_at desc')      
  end

  #view the answer for the current user's asked question
  def show_answer
    @question = ExpertQuestion.find(params[:id])
    if @question.submitted_by != session[:user_id]
      flash[:notice] = "You are not authorized to access this page as you are not listed as the creator of that particular question."
      redirect_to :action => 'view_questions'
      return
    end
    @question.update_attribute(:has_read, true)
  end
    
end
