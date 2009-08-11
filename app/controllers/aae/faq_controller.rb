# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::FaqController < ApplicationController
  layout 'aae'
  before_filter :login_required
  before_filter :check_purgatory
  protect_from_forgery :except => [:create] 
  
  # Display the "new FAQ form" when resolving an "ask an expert" question
  def new_faq
    @submitted_question = SubmittedQuestion.find_by_id(params[:squid])
    if !@submitted_question
      flash[:failure] = "Invalid question."
      redirect_to resolved_url
      return
    end
  end
  
  # Save the new FAQ created from the ask an expert question
  def create
    submitted_question = SubmittedQuestion.find(params[:squid])
    
    if !submitted_question
      flash[:failure] = "Invalid question entered"
      redirect_to resolved_url
      return
    end
    if !params[:question] or params[:question].strip == '' or !params[:answer] or params[:answer].strip == ''
      flash[:failure] = "Please enter both a question and an answer."
      redirect_to :action => :new_faq, :squid => submitted_question.id
      return
    end
    
    if Rails.env == 'production'
      url = URI.parse("#{AppConfig.configtable['faq_site']}/expert/create_faq")
      http = Net::HTTP.new(url.host, url.port)
      response = http.post(url.path, "question=#{params[:question]}&answer=#{params[:answer]}&squid=#{submitted_question.id}&userlogin=#{@currentuser.login}")
    
      if response.class == Net::HTTPOK
        flash[:success] = "Faq has been successfully saved in the faq system at http://faq.extension.org."
        redirect_to aae_question_url(:id => submitted_question.id)
      else
        flash[:failure] = "Something went wrong saving your faq. Please try entering it again or check back at another time."
        redirect_to :action => :new_faq, :squid => submitted_question.id
      end
    else
      flash[:failure] = "A new faq has not been created as you are in development mode. Please uncomment the necessary code and add in your local faq host into the config in order to get this to work."
      redirect_to :action => :new_faq, :squid => submitted_question.id
    end
  end    
  
end