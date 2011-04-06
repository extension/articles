# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class People::ListsController < ApplicationController
  layout 'people'
  before_filter :login_required, :check_purgatory, :except => [:show, :postinghelp, :about]
  before_filter :login_optional, :only => [:show, :postinghelp, :about]
   
  def index
    @listoflists = List.paginate(:all, :order => "name", :page => params[:page])
  end
  
  def postinghelp
  end
  
  def about
  end
    
  def show
    @list = List.find_by_name_or_id(params[:id])
    if(@list.nil?)  
      flash[:error] = 'That list does not exist'  
      return(redirect_to(:action => 'index'))
    end
    return redirect_to(people_community_url(@list.community))
  end
    
end