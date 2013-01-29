# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module People::ActivityDisplayHelper

  def link_to_object_action(linkobject,includefeedkey=false)
    if(linkobject.is_a?(Community))
      urlparams = {:action => :list, :community => linkobject.id, :communityactivity => 'all'}
    else
      urlparams = {:action => :list, linkobject.class.name.downcase.to_sym => linkobject.id, :communityactivity => 'all'}
    end
    if(includefeedkey)
      urlparams[:feedkey] = @currentuser.feedkey
    end
    return link_to(linkobject.name, url_for(urlparams))
  end

  def link_to_people_community(community,displayna = true)
    if(!community.nil?)
      "<a href='#{people_community_url(community.id)}'>#{community.name}</a>"
    elsif(displayna)
      "none"
    else
      "&nbsp;"
    end
  end

  def link_to_user(user,opts = {})
    show_unknown = opts.delete(:show_unknown) || false
    show_systemuser = opts.delete(:show_systemuser) || false
    nolink = opts.delete(:nolink) || false

    if user.nil?
      show_unknown ? 'Unknown' : 'System'
    elsif(user.id == 1 and !show_systemuser)
      'System'
    elsif(nolink)
      "#{user.fullname}"
    else
      "<a href='#{url_for(:controller => '/people/colleagues', :action => :showuser, :id => user.login)}'>#{user.fullname}</a>"
    end
  end

  def link_to_activity_application(aa)
    "<a href='#{url_for(:controller => '/people/activity', :action => :list, :activityapplication => aa.id)}'>#{aa.displayname}</a>"
  end

  def activity_to_s(activity,opts = {})
    translate_options = {}

    communityview = opts[:communityview] || false
    userview = opts[:userview] || false
    nolink = opts[:nolink] || false
    wantstitle = opts[:wantstitle] || false

    userlink = link_to_user(activity.user,{:nolink => nolink})
    usertext = userview ? '' : "#{userlink} "
    translate_options[:username] =  activity.user.nil? ? 'unknown' : activity.user.fullname
    translate_options[:usertext] =  usertext


    creatorlink = link_to_user(activity.creator,{:nolink => nolink})
    translate_options[:creatortext] =  creatorlink

    if(!activity.activity_application.nil?)
      aalink = activity.activity_application.displayname
      translate_options[:activityapplication] =  aalink
    elsif(activity.activitycode == Activity::LOGIN_OPENID)
      # special case of external OPENID login
      translate_options[:activityapplication] =  activity.activity_uri
    end


    if(!activity.community.nil?)
      communityname = activity.community.name
      communitylink = nolink ? activity.community.name : link_to_people_community(activity.community)
      communitytext = communityview ? "community" : "#{communitylink} community"
      translate_options[:communitytext] =  communitytext
    else
      translate_options[:communitytext] =  'unknown'
      communityname = opts[:communityname] || "Unknown Community"
    end

    if(!activity.colleague.nil?)
      colleaguelink = link_to_user(activity.colleague,{:nolink => nolink})
      translate_options[:colleaguetext] =  colleaguelink
    end

    if(activity.activitycode == Activity::INVITATION)
      translate_options[:emailaddress] =  activity.additionaldata[:invitedemail]
    end

    if(communityview)
      commmunitytitletext = "#{communityname}: "
      translate_options[:commmunitytitletext] =  commmunitytitletext
    else
      translate_options[:commmunitytitletext] = ''
    end


    title = I18n.translate("activitytitle.#{Activity::ACTIVITY_LOCALE_STRINGS[activity.activitycode]}",translate_options)
    body = I18n.translate("activitybody.#{Activity::ACTIVITY_LOCALE_STRINGS[activity.activitycode]}",translate_options)

    if(wantstitle)
      {:title => title, :body => body}
    else
      body
    end
  end




end