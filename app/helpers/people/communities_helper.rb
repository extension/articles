# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module People::CommunitiesHelper
  
  def community_class(community)
    if community.is_institution? 
      "institution"
    elsif community.is_widget?
      "widget"
    else 
      "community"
    end
  end
  
  def change_community_connection_link(container,community,label,connectaction,linkoptions = {})
    url = {:controller => '/people/communities', :action => :change_my_connection, :id => community.id, :connectaction => connectaction}
    if(container == 'nointerest')
      color = 'white'
    else
      color = 'ffe2c8'
    end
    progress = "<p><img src='/images/common/ajax-loader-#{color}.gif' /> Saving... </p>"
    return link_to_remote(label, {:url => url, :loading => update_page{|p| p.replace_html(container,progress)}}, linkoptions)
  end
  
  def get_communitytypes_for_select
    returnarray = []
    Community::ENTRYTYPES.keys.sort.each do |key|
      if(Community::ENTRYTYPES[key][:allowadmincreate])
        returnarray << [I18n.translate("communities.#{Community::ENTRYTYPES[key][:locale_key]}"),key]
      end
    end
    returnarray
  end
  
  
  def makecommunityusercsvstring(user,community)
     #eXtensionID,First Name,Last Name,Email,Title,Position,Institution,Location,County,Agreement Status,Connection,Account Created,Connection Created,Connection Updated
     csvstring = user.login+','
     csvstring += user.first_name.tr(',',' ')+','
     csvstring += user.last_name.tr(',',' ')+','
     csvstring += user.email+','
     csvstring += ((user.phonenumber.nil? or user.phonenumber == '') ? 'not specified' : number_to_phone(user.phonenumber,:area_code => true))+','
     csvstring += ((user.title.nil? or user.title == '') ? 'not specified' : user.title.tr(',',' '))+','
     csvstring += ((user.position.nil? or user.position == '') ? 'not specified' : user.position.name.tr(',',' '))+','
     csvstring += user.primary_institution_name.tr(',',' ')+','
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
    csvstring += user.connection_display(community)
    
 	  csvstring += ','
    csvstring += user.created_at.strftime("%Y/%m/%d %H:%M:%S")

 	  csvstring += ','
    csvstring += user.community_connect_date(community,"created").strftime("%Y/%m/%d %H:%M:%S")
 	  csvstring += ','
    csvstring += user.community_connect_date(community,"updated").strftime("%Y/%m/%d %H:%M:%S")
    csvstring += ','
    csvstring += community.name
    
 	  return csvstring
  end
  
  def community_connection_link(container,community,showuser,label,connectaction,title,confirm = nil)
    urloptions = {:controller => '/people/communities', :action => :modify_user_connection, :id => community.id, :userid => showuser.id }
    urloptions.merge!({:connectaction => connectaction})
    progress = "<img src='/images/common/ajax-loader-white.gif' /> Saving..."
    loading = update_page{|p| p.replace_html(container,progress)}
    options = {:url => urloptions, :loading => loading}
    options.merge!({:confirm => confirm}) if(!confirm.nil?)
    htmloptions = {:title => title}
    return link_to_remote(label,options,htmloptions)
  end 
  
  def community_connection_links(container,community,showuser,connectaction)
    remove_leader_link = community_connection_link(container,community,showuser,(community.is_institution? ? 'remove from inst. team' : 'remove leadership'),'removeleader',(community.is_institution? ? 'Remove from the Institutional Team' : 'Remove user from leadership'))
    remove_member_link = community_connection_link(container,community,showuser,'remove','removemember',"Remove user from this community","Are you sure you want to remove this person from the community?")
    add_member_link = community_connection_link(container,community,showuser,'make member','addmember',"Make user a member")
    add_leader_link = community_connection_link(container,community,showuser,(community.is_institution? ? 'add to inst. team' : 'make leader'),'addleader',(community.is_institution? ? 'Add to Institutional Team' : 'Make user a community leader'))
    sendagain_invite_link = community_connection_link(container,community,showuser,'send again','invitereminder',"Send an invitation reminder")
    rescind_invite_link = community_connection_link(container,community,showuser,'rescind','rescindinvitation',"Rescind community invitation","Are you sure you want rescind this invitation?")
    invite_member_link = community_connection_link(container,community,showuser,'invite as member','invitemember',"Invite user to be a community member")

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
  
  def link_shared_tags(shared_tag_list_names)
    shared_tag_list_names.map{|tagname|
      link_to(tagname,:controller=>:communities,:action=> :tags,:taglist=>tagname)
    }.join(Tag::JOINER)
  end
  
  
  def make_community_userlist_filter_line(community,options = {})
    filteredparameters = ParamsFilter.new(User.filteredparameters,params)    
    returntext = '<ul id="usertypes">'
    displayfilter = params[:connectiontype].nil? ? 'all' : params[:connectiontype]
    
  
    # joined
    if(User.filtered_count(options.merge({:community => community, :connectiontype => 'joined'})) > 0)
      if(displayfilter == 'joined')
        returntext += "<li class='filtered'>Joined</li>"
      else
        returntext += "<li>#{link_to('Joined',userlist_people_community_url(community.id, filteredparameters.option_values_hash.merge({:connectiontype => 'joined'})))}</li>"
      end
    end
    
    # leaders
    if(User.filtered_count(options.merge({:community => community, :connectiontype => 'leaders'})) > 0)
      if(displayfilter == 'leaders')
        returntext += "<li class='filtered'>Leaders</li>"
      else
        returntext += "<li>#{link_to('Leaders',userlist_people_community_url(community.id, filteredparameters.option_values_hash.merge({:connectiontype => 'leaders'})))}</li>"
      end
    end
        
    # members
    if(User.filtered_count(options.merge({:community => community, :connectiontype => 'members'})) > 0)
      if(displayfilter == 'members')
        returntext += "<li class='filtered'>Members</li>"
      else
        returntext += "<li>#{link_to('Members',userlist_people_community_url(community.id, filteredparameters.option_values_hash.merge({:connectiontype => 'members'})))}</li>"
      end
    end
    
    # wantstojoin
    if(community.memberfilter == Community::MODERATED and User.filtered_count(options.merge({:community => community, :connectiontype => 'wantstojoin'})) > 0)
      if(displayfilter == 'wantstojoin')
        returntext += "<li class='filtered'>Wants to Join</li>"
      else
        returntext += "<li>#{link_to('Wants to Join',userlist_people_community_url(community.id, filteredparameters.option_values_hash.merge({:connectiontype => 'wantstojoin'})))}</li>"
      end
    end
    
    # interest
    if(User.filtered_count(options.merge({:community => community, :connectiontype => 'interest'})) > 0)
      if(displayfilter == 'interest')
        returntext += "<li class='filtered'>Interest</li>"
      else
        returntext += "<li>#{link_to('Interest',userlist_people_community_url(community.id, filteredparameters.option_values_hash.merge({:connectiontype => 'interest'})))}</li>"
      end
    end
    
    # invited
    if(User.filtered_count(options.merge({:community => community, :connectiontype => 'invited'})) > 0)
      if(displayfilter == 'invited')
        returntext += "<li class='filtered'>Invited</li>"
      else
        returntext += "<li>#{link_to('Invited',userlist_people_community_url(community.id, filteredparameters.option_values_hash.merge({:connectiontype => 'invited'})))}</li>"
      end
    end
    returntext += '</ul>'
    returntext
  end
  
  def list_stat_line(hash)
    "<span class='bignumber'>#{hash[:messages]}</span> messages sent by <span class='bignumber'>#{hash[:senders]}</span> senders (total size: #{number_to_human_size(hash[:totalsize])})"
  end
end

