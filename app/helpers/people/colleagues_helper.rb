# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module People::ColleaguesHelper
  
  def makeusercsvstring(user)
    #eXtensionID,First Name,Last Name,Email,Title,Position,Institution,Location,County,Agreement Status,Account Created
    csvstring = user.login+','
    csvstring += user.first_name.tr(',',' ')+','
    csvstring += user.last_name.tr(',',' ')+','
    csvstring += user.email+','
    csvstring += ((user.phonenumber.nil? or user.phonenumber == '') ? 'not specified' : number_to_phone(user.phonenumber,:area_code => true))+','
    csvstring += ((user.title.nil? or user.title == '') ? 'not specified' : user.title.tr(',',' '))+','
    csvstring += ((user.position.nil? or user.position == '') ? 'not specified' : user.position.name.tr(',',' '))+','
    csvstring += ((user.institution.nil?) ? 'not specified' : user.institution.name.tr(',',' '))+','
    csvstring += ((user.location.nil? or user.location == '') ? 'not specified' : user.location.name.tr(',',' '))+','
    csvstring += ((user.county.nil? or user.county == '') ? 'not specified' : user.county.name.tr(',',' '))+','
  	
  	if !user.contributor_agreement.nil?
  	  if user.contributor_agreement 
  	    csvstring += 'Accepted'
  	  else
  	    csvstring += 'Did Not Accept'
  	  end
  	else
	    csvstring += 'Not Yet Reviewed'
	  end
	  
	  csvstring += ','
    csvstring += user.created_at.strftime("%Y/%m/%d %H:%M:%S")
	  
	  return csvstring
  end

  def colleague_community_connection_link(container,community,showuser,label,connectaction,title,confirm = nil)
    urloptions = {:controller => '/people/colleagues', :action => :modify_community_connection, :id => showuser.id, :communityid => community.id }
    urloptions.merge!({:connectaction => connectaction})
    progress = "<img src='/images/common/ajax-loader-white.gif' /> Saving..."
    loading = update_page{|p| p.replace_html(container,progress)}
    options = {:url => urloptions, :loading => loading}
    options.merge!({:confirm => confirm}) if(!confirm.nil?)
    htmloptions = {:title => title}
    return link_to_remote(label,options,htmloptions)
  end 

  def colleague_community_connection_links(container,community,showuser,connectaction)
    remove_leader_link = colleague_community_connection_link(container,community,showuser,'remove leadership','removeleader',"Remove user from leadership")
    remove_member_link = colleague_community_connection_link(container,community,showuser,'remove','removemember',"Remove user from this community","Are you sure you want to remove this person from the community?")
    add_member_link = colleague_community_connection_link(container,community,showuser,'make member','addmember',"Make user a member")
    add_leader_link = colleague_community_connection_link(container,community,showuser,'make leader','addleader',"Make user a community leader")
    sendagain_invite_link = colleague_community_connection_link(container,community,showuser,'send again','invitereminder',"Send an invitation reminder")
    rescind_invite_link = colleague_community_connection_link(container,community,showuser,'rescind','rescindinvitation',"Rescind community invitation","Are you sure you want rescind this invitation?")
    invite_member_link = colleague_community_connection_link(container,community,showuser,'invite as member','invitemember',"Invite user to be a community member")

    # special cases
    if(connectaction == 'invitereminder')
      returnstring = 'Sent Reminder'
    else
      connection = showuser.connection_with_community(community)
      case connection

      when 'invitedleader'
        returnstring = "#{rescind_invite_link} #{sendagain_invite_link} #{add_leader_link}"
      when 'invitedmember'
        returnstring = "#{rescind_invite_link} #{sendagain_invite_link} #{add_member_link}"
      when 'wantstojoin'
        returnstring = "#{add_member_link}"
      when 'interest'
        returnstring = "#{invite_member_link}"
      when 'leader'
        returnstring = "#{remove_leader_link}"
      when 'member'
        returnstring = "#{add_leader_link} #{remove_member_link}"
      when 'none'
        returnstring = ''
      else
        returnstring = ''
      end
    end

    returnstring
  end
  
end

