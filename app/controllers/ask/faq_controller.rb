# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Ask::FaqController < ApplicationController
  
  
  # Display the "new FAQ form" when resolving an "ask an expert" question
  def new_faq
    @submitted_question = SubmittedQuestion.find_by_id(params[:squid])
    
    if !@submitted_question
      flash[:failure] = "Invalid question."
      go_back
      return
    end
    
    @question = @submitted_question.to_faq(User.current_user)
    @revision = @question.revisions[0]

    if params[:question] && params[:answer]
      @revision.question_text = params[:question]
      @revision.answer = params[:answer]  
    end
  end
  
  # Save the new FAQ used to resolve an "ask an expert" question
  def create
    @submitted_question = SubmittedQuestion.find(params[:squid])

    @question = Question.new(params[:question])
    
    #remove all whitespace in questions and answers before putting into db.
    params[:revision].collect{|key, val| params[:revision][key] = val.strip}
    
    @revision = Revision.new(params[:revision])
    
    @revision.user = User.current_user   
    @question.status = Question::STATUS_DRAFT
    @question.draft_status = Question::STATUS_DRAFT
    
    if !valid_ref_question?
      flash[:failure] = "Invalid question number entered."
      error_render("new_faq")
      return
    end
    
    if @question.save
	    if session[:watch_pref] == "1"
        User.current_user.questions << @question
        User.current_user.save
      end
      
      flash[:success] = "Your new FAQ has been saved"
      # remove any list context in the session so that return to list, next question, etc. 
      # will not show up when viewing the newly created faq
      session[:context] = nil
      redirect_to :controller => 'questions', :action => 'show', :id => @question.id
    else
      flash[:failure] = "There was an error saving the new faq. Please try again."
      error_render("new_faq")
    end	      
  end # end create
  
  def show_faq
    @question = Question.find_by_id(params[:id])
    @submitted_question = SubmittedQuestion.find_by_id(params[:squid])
    
    if !@question or !@submitted_question
      go_back
      return
    end
  end
  
  # Show a list of possible FAQs that could be used to resolve an ask an expert question
  def show_duplicates
    @errors = []
    @submitted_question = SubmittedQuestion.find_by_id(params[:squid])
    if !@submitted_question
      flash[:failure] = "Please specify a valid question."
      redirect_to home_url
      return
    end

    if params[:query].nil? || params[:query].strip.length == 0
      flash[:failure] = 'You must enter some search terms.'
      redirect_to :controller => :expert, :action => :question, :id => @submitted_question.id
      return
    end
    
    keywords = params[:query]
    
    begin
      @search_results = Question.full_text_search(keywords, 1, 'and')
    rescue Exception => e
      flash[:failure] = "The search could not be successfully completed.e" + e.message
      email_search_error(request.host, params[:query], e.message)
      redirect_to :action => :question, :query => params[:query], :id => params[:squid]
      return
    end
  end
  
end