# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module People::InvitationsHelper

  def make_filter_list_item(action,show,showparam)
    if(show == showparam)
      returntext = "<li class='filtered'>#{showparam.capitalize}</li>"
    else
      returntext = "<li>#{link_to("#{showparam.capitalize}", :action => action, :show => showparam)}</li>"
    end
    return returntext
  end
    

  def make_invitations_filter_line(action)
    show = params[:show].nil? ? 'pending' : params[:show]
    case action
    when 'index'
      all_count = Invitation.count
      completed_count = Invitation.completed.count
      pending_count = Invitation.pending.count
      invalidemail_count = Invitation.invalidemail.count
    when 'mine'
      all_count = Invitation.byuser(@currentuser).count
      completed_count = Invitation.byuser(@currentuser).completed.count
      pending_count = Invitation.byuser(@currentuser).pending.count
      invalidemail_count = Invitation.byuser(@currentuser).invalidemail.count
    else
      return ''
    end
    
    if(all_count == 0)
      return ''
    end


    returntext = '<ul id="invitationtypes">'
    # all
    returntext += make_filter_list_item(action,show,'all')
    
    # pending
    if(pending_count > 0)
      returntext += make_filter_list_item(action,show,'pending')
    end
  
    # accepted
    if(completed_count >  0)
      returntext += make_filter_list_item(action,show,'completed')
    end
  
    # invalid
    if(invalidemail_count > 0)
      returntext += make_filter_list_item(action,show,'invalidemail')
    end
    
    returntext += '</ul>'
    returntext
  end

end