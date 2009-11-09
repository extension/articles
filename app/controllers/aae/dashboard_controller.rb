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
   list_view
   set_filters
   filter_string_helper
    
    t = Time.now
    last6months = (t - 180*24*60*60).strftime("%Y-%m-%d %H:%M:%S")
    today = (Time.now).strftime("%Y-%m-%d %H:%M:%S")
    
    filteroptions = {:category => @category, :location => @location, :county => @county, :source => @source}
    filtered_conds = SubmittedQuestion.filterconditions(filteroptions)[:conditions]
    filtered_includes = SubmittedQuestion.filterconditions(filteroptions)[:include]
  #  @submitted_questions = SubmittedQuestion.submitted.filtered(filteroptions).ordered(@order).listdisplayincludes    #.paginate(:page => params[:page]
    @assignees = SubmittedQuestion.get_assignees(last6months, today, filtered_conds, filtered_includes)
       
     # on this one we limit being the recipient to resolving (resolved, rejected, no answer) or assigning to someone, no dangling recipients...
     # because we cannot tell when something is assigned if it got resolved until later, some of the resolved are counted twice here, standing in for an 'assigned'
   #count the 'previously assigned'
   assigned_resolved = User.get_num_times_assigned(last6months,today ," join users on users.id=initiated_by_id ", " and initiated_by_id=previous_handling_recipient_id  ", 
           filtered_conds, filtered_includes)
   #count any initiating (resolved, rejected, no answer) entries
   all_resolved = User.get_num_times_assigned(last6months, today, " join users on users.id=initiated_by_id ", " and initiated_by_id=users.id ",
            filtered_conds, filtered_includes)
   #count those who assigned themselves explicitly as dups since they were counted above already in assigned_resolved assuming not their own assigner, and for an 'initiator of resolution'  
   dup_set = User.get_num_times_assigned(last6months, today, " join users on users.id=initiated_by_id ", " and initiated_by_id=recipient_id ", 
            filtered_conds, filtered_includes)  
   subtotasgn = SubmittedQuestion.add_vals(all_resolved, assigned_resolved, '+')
   @assgnscompls = SubmittedQuestion.add_vals(subtotasgn, dup_set, '-')
   
      #  This is user id touching any initiated_by_id or recipient_id for ASSIGNED_TO or any resolved (resolved, rejected, no answer) id; in 3 steps because one statement can't handle a multiple join on users.id in MAMP (goes to never-never land)
      #  This methodology is due to the constraints of MAMP
   totrecips = User.get_num_times_assigned(last6months, today, "join users on users.id=recipient_id " ," and recipient_id=users.id ", filtered_conds, filtered_includes)
   totboth = User.get_num_times_assigned(last6months, today, "join users on users.id=initiated_by_id " ," and (initiated_by_id=users.id and recipient_id=users.id) ", filtered_conds, filtered_includes)
   subtot = SubmittedQuestion.add_vals(all_resolved, totrecips, '+')
   @totalassgns = SubmittedQuestion.add_vals(subtot, totboth, '-')
 
    @avgscompl=User.get_avg_resp_time_only(last6months, today, filtered_conds, filtered_includes)
    @avgsheld = User.get_avg_handling_time(last6months, today, filtered_conds, filtered_includes) 
    
  
  end
  
  
  
end