# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module People::ListsHelper
  
  def link_to_mailinglist(mailinglist)
    "<a href='#{url_for(:controller => 'people/lists', :action => :show, :id => mailinglist.id)}'>#{mailinglist.name}</a>"
  end
  
  def list_subscriber_count(list)
    if !list.managed? or !list.dropforeignsubscriptions 
  	  subscribers = list.list_subscriptions.subscribers.count + list.list_subscriptions.noidsubscribers.count 
  	else
  	  subscribers = list.list_subscriptions.subscribers.count
  	end
  	return subscribers.to_s
  end
  
  def listpost_activity_to_s(listpost,opts={})
    listview = opts[:listview] || false 
    wantstitle = opts[:wantstitle] || false
    
    if(listpost.user.nil?)
      usertext = listpost.senderemail
    else
      usertext = link_to_user(listpost.user)
    end
    
    listtext = listview ? "#{link_to_mailinglist(listpost.list)} mailing list" : "mailing list"
    titlename = listpost.user.nil? ? "#{listpost.senderemail}" : "#{listpost.user.fullname}" 
    title = "POSTED A MAILING LIST MESSAGE: #{titlename}" 
    body = "#{usertext} posted a message to the #{listtext}"
    
    if(wantstitle)
      {:title => title, :body => body}
    else
      body  
    end
    
  end
  
  def link_to_people_community_connection(community, communityconnection, linktext=nil, displayna = true)
    if(community.nil?)
      return displayna ? "N/A" : "&nbsp;"
    elsif(!linktext.blank?)
      "<a href='#{userlist_people_community_url(community.id, :connectiontype => communityconnection.connectiontype)}'>#{linktext}</a>"
    else
      "<a href='#{userlist_people_community_url(community.id, :connectiontype => communityconnection.connectiontype)}'>#{communityconnection.connectiontype.capitalize}</a>"
    end
  end
  
  def list_description(list)
    if !list.community.nil?
   	  description = "<p>This mailing list is connected to the #{link_to_people_community(list.community)} community and the list membership is updated from those that have a  #{link_to_people_community_connection(list.community, list.communityconnection)} connection with the community.</p>"
    elsif list.is_announce_list? 
   	  description = "<p>This mailing list is associated with all currently registered eXtensionID's that have opted to receive announcements from eXtension</p>"
    else
   	  description = "<p>This mailing list is not currently connected to a community.</p>"
    end
    
    if(!@currentuser.nil?)
      description +=  "<p>To send email to this list:  <a href='mailto:#{list.name}@lists.extension.org'>#{list.name}@lists.extension.org</a></p>"
    end
    return description
  end
  
  def list_stat_line(hash)
    if(hash[:listcount].nil?)
      "<span class='bignumber'>#{hash[:messages]}</span> messages sent by <span class='bignumber'>#{hash[:senders]}</span> senders (total size: #{number_to_human_size(hash[:totalsize])})"
    else
      "<span class='bignumber'>#{hash[:messages]}</span> messages sent by <span class='bignumber'>#{hash[:senders]}</span> senders to <span class='bignumber'>#{hash[:listcount]}</span> lists (total size: #{number_to_human_size(hash[:totalsize])})"
    end
  end
  
  def change_list_subscription_link(container,list,subscribeaction,linktext,linkoptions = {})
    url = {:controller => '/people/lists', :action => :change_my_subscription, :id => list.id, :subscribeaction => subscribeaction}
    color = 'ffe2c8'
    progress = "<p><img src='/images/common/ajax-loader-#{color}.gif' /> Saving... </p>"
    return link_to_remote(linktext, {:url => url, :loading => update_page{|p| p.replace_html(container,progress)}}, linkoptions)
  end
  
  def change_list_moderation_link(container,list,moderationaction,linktext,linkoptions = {})
    url = {:controller => '/people/lists', :action => :change_my_moderation, :id => list.id, :moderationaction => moderationaction}
    color = 'white'
    progress = "<p><img src='/images/common/ajax-loader-#{color}.gif' /> Saving... </p>"
    return link_to_remote(linktext, {:url => url, :loading => update_page{|p| p.replace_html(container,progress)}}, linkoptions)
  end
  
  def link_by_permission_and_count(list,count,text,params)
    if(@currentuser.lists.include?(list) or admin_mode?)
      (count == 0) ? text : link_to(text,params)
    else
      text
    end
  end
  
  def make_list_ownerlist_filter_line(list)
    returntext = '<ul id="usertypes">'
    displayfilter = params[:type].nil? ? 'idowners' : params[:type]
    
    # idowners
    if(list.list_owners.idowners.count > 0)
      if(displayfilter == 'idowners')
        returntext += "<li class='filtered'>Owners (with eXtensionIDs)</li>"
      else
        returntext += "<li>#{link_to('Owners (with eXtensionIDs)',ownerlist_people_list_url(list.id, :type => 'idowners'))}</li>"
      end
    end

    # noidowners
    if(!list.managed or !list.dropforeignsubscriptions)
      if(list.list_owners.noidowners.count > 0)
        if(displayfilter == 'noidowners')
          returntext += "<li class='filtered'>Owners (without eXtensionIDs)</li>"
        else
          returntext += "<li>#{link_to('Owners (without eXtensionIDs)',ownerlist_people_list_url(list.id, :type => 'noidowners'))}</li>"
        end
      end
    end

    returntext += '</ul>'
    returntext
  end
  
  def make_list_userlist_filter_line(list)
    returntext = '<ul id="usertypes">'
    displayfilter = params[:type].nil? ? 'subscribers' : params[:type]
    
    # subscribers
    if(list.list_subscriptions.subscribers.count > 0)
      if(displayfilter == 'subscribers')
        returntext += "<li class='filtered'>Subscribers</li>"
      else
        returntext += "<li>#{link_to('Subscribers',subscriptionlist_people_list_url(list.id, :type => 'subscribers'))}</li>"
      end
    end

    # optout
    if(list.list_subscriptions.optout.count > 0)
      if(displayfilter == 'optout')
        returntext += "<li class='filtered'>Opt-out</li>"
      else
        returntext += "<li>#{link_to('Opt-out',subscriptionlist_people_list_url(list.id, :type => 'optout'))}</li>"
      end
    end

    # ineligible
    if(list.list_subscriptions.ineligible.count > 0)
      if(displayfilter == 'ineligible')
        returntext += "<li class='filtered'>Ineligible</li>"
      else
        returntext += "<li>#{link_to('Ineligible',subscriptionlist_people_list_url(list.id, :type => 'ineligible'))}</li>"
      end
    end

    # unconnected
    if(list.managed and !list.dropunconnected)
      if(list.unconnected_subscription_count > 0)
        if(displayfilter == 'unconnected')
          returntext += "<li class='filtered'>Subscribers (unconnected)</li>"
        else
          returntext += "<li>#{link_to('Subscribers (unconnected)',subscriptionlist_people_list_url(list.id, :type => 'unconnected'))}</li>"
        end
      end
    end

    # noidsubscribers
    if(!list.managed or !list.dropforeignsubscriptions)
      if(list.list_subscriptions.noidsubscribers.count > 0)
        if(displayfilter == 'noidsubscribers')
          returntext += "<li class='filtered'>Subscribers (without eXtensionIDs)</li>"
        else
          returntext += "<li>#{link_to('Subscribers (without eXtensionIDs)',subscriptionlist_people_list_url(list.id, :type => 'noidsubscribers'))}</li>"
        end
      end
    end

    returntext += '</ul>'
    returntext
  end
  
end
