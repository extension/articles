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

    if(!activity.activity_object.nil?)
      translate_options[:activityobject_type] = activityobject_type_string(activity.activity_object)
      translate_options[:activityobject_title] = activityobject_title_string(activity.activity_object)
      translate_options[:activityobject_text] = activityobject_body_string(activity.activity_object,opts)
    end

    title = I18n.translate("activitytitle.#{Activity::ACTIVITY_LOCALE_STRINGS[activity.activitycode]}",translate_options)
    body = I18n.translate("activitybody.#{Activity::ACTIVITY_LOCALE_STRINGS[activity.activitycode]}",translate_options)

    if(wantstitle)
      {:title => title, :body => body}
    else
      body
    end
  end


  def activityobject_type_string(activityobject)
    if(translatestring = ActivityObject::ENTRYTYPELABELS[activityobject.entrytype])
      return I18n.translate("activityobject.#{translatestring}")
    else
      return I18n.translate("activityobject.unknown")
    end
  end

  def activityobject_title_string(activityobject)
    if(ActivityObject::WIKITYPES.include?(activityobject.entrytype))
      tmptitle = activityobject.displaytitle.tr('_',' ')
      output_title = (tmptitle.length > 50) ? tmptitle.mb_chars[0..49]+'...' : tmptitle
      return_title_text = "#{output_title}"
    else
      output_title = (activityobject.displaytitle.length > 50) ? activityobject.displaytitle.mb_chars[0..49]+'...' : activityobject.displaytitle
      return_title_text = "##{activityobject.foreignid}: #{output_title}"
    end

    return return_title_text
  end


  def activityobject_uri_string(activityobject)
    if(activityobject.entrytype == ActivityObject::SYSWIKI_PAGE)
      return_uri_string = "#{activityobject.activity_application.link_uri}/docs/#{activityobject.fulltitle}"
    elsif(ActivityObject::WIKITYPES.include?(activityobject.entrytype))
      return_uri_string = "#{activityobject.activity_application.link_uri}/#{activityobject.fulltitle}"
    elsif(activityobject.entrytype == ActivityObject::AAE)
      return_uri_string = "#{activityobject.activity_application.link_uri}/aae/question/#{activityobject.foreignid}"
    elsif(activityobject.entrytype == ActivityObject::EVENT)
      return_uri_string = "#{activityobject.activity_application.link_uri}/events/#{activityobject.foreignid}"
    elsif(activityobject.entrytype == ActivityObject::FAQ)
      return_uri_string = "#{activityobject.activity_application.link_uri}/publish/show/#{activityobject.foreignid}"
    else
      return nil
    end
    return return_uri_string
  end



  def activityobject_body_string(activityobject,options={})
    nolink = options[:nolink].nil? ? false : options[:nolink]
    htmltext = options[:htmltext].nil? ? true : options[:htmltext]


    if(nolink)
      bodytext = "#{activityobject_type_string(activityobject)} #{activityobject_title_string(activityobject)}"
    else
      bodytext = "<a href=\"#{activityobject_uri_string(activityobject)}\">#{activityobject_type_string(activityobject)} #{activityobject_title_string(activityobject)}</a>"
    end

    return bodytext
  end

end