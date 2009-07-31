# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::QuestionController < ApplicationController
  layout 'aae'
  before_filter :filter_string_helper
  before_filter :login_required
  
  def index
    @submitted_question = SubmittedQuestion.find_by_id(params[:id])
    
    if @submitted_question.nil?
      do_404
      return
    end
    
    @contributing_question = @submitted_question.contributing_question
    if @contributing_question
      @contributing_question.entrytype == SearchQuestion::FAQ ? @type = 'FAQ' : @type = 'AaE Question'
    end
    
    @categories = Category.root_categories
    @category_options = @categories.map{|c| [c.name,c.id]}
      
    @submitter_name = @submitted_question.submitter_fullname
      
    if @submitted_question.categories and @submitted_question.categories.length > 0
      @category = @submitted_question.categories.first
      @category = @category.parent if @category.parent
      @category_id = @category.id
      @users = @category.users.find(:all, :select => "users.*", :order => "users.first_name")
    # find subcategories
      @sub_category_options = [""].concat(@category.children.map{|sq| [sq.name, sq.id]})
      if subcategory = @submitted_question.categories.find(:first, :conditions => "parent_id IS NOT NULL")
        @sub_category_id = subcategory.id
      end
    else
      @sub_category_options = [""]    
    end
    
  end
  
  def view
    @aae_search_item = SearchQuestion.find_by_entrytype_and_foreignid(params[:type], params[:qid])
    if !@aae_search_item
      flash[:failure] = "Invalid question parameters"
      redirect_to incoming_url
      return
    end
    
    @aae_search_item.entrytype == SearchQuestion::AAE ? @type = 'Ask an Expert Question' : @type = 'FAQ'
  end
  
end