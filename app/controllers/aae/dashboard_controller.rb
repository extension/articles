# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::DashboardController < ApplicationController

  layout 'aae'
  before_filter :login_required
  before_filter :check_purgatory

  
  def index
    if err_msg = params_errors
      list_view_error(err_msg)
      return
    end
    
    #set the instance variables based on parameters
  #  list_view
  #  set_filters
  #  filter_string_helper
    
    t = Time.now
    last6months = (t - 180*24*60*60).strftime("%Y-%m-%d %H:%M:%S")
    today = (Time.now).strftime("%Y-%m-%d %H:%M:%S")
    
    filteroptions = {:category => @category, :location => @location, :county => @county, :source => @source}
    @submitted_questions = SubmittedQuestion.submitted.filtered(filteroptions).ordered(@order).listdisplayincludes    #.paginate(:page => params[:page])
 #   @submitted_questions = SubmittedQuestion.find(:all, :conditions => "submitted_questions.status_state = #{SubmittedQuestion::STATUS_SUBMITTED} AND submitted_questions.spam = FALSE", :order => "created_at DESC")
  #  @assignees = User.find(:all, :select => "submitted_questions.created_at sqcreated_at, submitted_questions.id sqid, users.id uid, last_login_at, user_id, last_name, first_name, login", :joins => "join submitted_questions on submitted_questions.user_id=users.id", :conditions =>  "submitted_questions.status_state = #{SubmittedQuestion::STATUS_SUBMITTED} AND submitted_questions.spam = FALSE", :order => "submitted_questions.created_at DESC")
    @assgnscompls= User.get_num_times_assigned(last6months,today , " and resolved_by=subject_user_id ", SubmittedQuestion.filterconditions(filteroptions)[:conditions],SubmittedQuestion.filterconditions(filteroptions)[:include])
    @totalassgns = User.get_num_times_assigned(last6months,today, "", SubmittedQuestion.filterconditions(filteroptions)[:conditions], SubmittedQuestion.filterconditions(filteroptions)[:include])
    @avgscompl=User.get_avg_resp_time_only(last6months, today, SubmittedQuestion.filterconditions(filteroptions)[:conditions], SubmittedQuestion.filterconditions(filteroptions)[:include])
    
    
  
  end
  
  
  
end