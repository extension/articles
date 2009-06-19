# === COPYRIGHT:
#  Copyright (c) 2005-2008 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module People::ProfileHelper
  
  def fields_for_social_network(social_network, &block)
    prefix = social_network.new_record? ? 'new' : 'existing'
    fields_for("socialnetworks[#{prefix}][]", social_network, &block)
  end
  
  def fields_for_user_email(user_email, &block)
    prefix = user_email.new_record? ? 'new' : 'existing'
    fields_for("useremails[#{prefix}][]", user_email, &block)
  end
  
  def add_socialnetwork_link(linktext,networkname) 
    link_to_remote(linktext, {:url => {:action => :xhr_newsocialnetwork, :networkname => networkname}, :method => :post}, :title => "#{linktext} Network: #{networkname}")
  end

  def add_otheremail_link(linktext) 
    link_to_function linktext do |page| 
      page.insert_html :bottom, :useremails, :partial => 'user_email', :locals => {:user_email => UserEmail.new }
    end
  end
    
  def accounturl_link(accounturl)
    return ( !accounturl.nil? and accounturl != '' and accounturl != "accounturl" ) ? "<a href=\"#{accounturl}\">#{accounturl}</a>" : ''
  end
  
  def accounturl_directions(social_network)
    SocialNetwork::NETWORKS.keys.include?(social_network.network) ? "<span class=\"directions\">#{SocialNetwork::NETWORKS[social_network.network][:urlformatnotice]}</span>" : ''
  end
  
end
