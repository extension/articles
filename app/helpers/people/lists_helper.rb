# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module People::ListsHelper

  
  def link_to_people_community_connection(community, communityconnection, linktext=nil, displayna = true)
    if(community.nil?)
      return displayna ? "N/A" : "&nbsp;"
    elsif(!linktext.blank?)
      "<a href='#{userlist_people_community_url(community.id, :connectiontype => communityconnection.connectiontype)}'>#{linktext}</a>"
    else
      "<a href='#{userlist_people_community_url(community.id, :connectiontype => communityconnection.connectiontype)}'>#{communityconnection.connectiontype.capitalize}</a>"
    end
  end

  
end
