# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Aae::SurveyController < ApplicationController
  layout 'aae'
  before_filter :login_required
  before_filter :admin_required, :only => [:public_results]
  before_filter :check_purgatory  
  
  def public
    if(!@response = AaePublicSurvey.find_by_user_id(@currentuser.id))
      @response = AaePublicSurvey.new
    end
  end
  
  def post_public_answer
    if(!@response = AaePublicSurvey.find_by_user_id(@currentuser.id))
      @response = AaePublicSurvey.new(:user => @currentuser)
    end
    
    attributes_to_update = {}
    if(params[:peer_review])
      attributes_to_update[:peer_review] = params[:peer_review]
    end
    
    if(params[:public_comment])
      attributes_to_update[:public_comment] = params[:public_comment]
    end
     
    @response.update_attributes(attributes_to_update)
    flash[:success] = "Thank you for your response."
    return redirect_to(:action => 'public')
  end
  
end
