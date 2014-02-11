# === COPYRIGHT:
#  Copyright (c) 2005-2011 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
# 
#  see LICENSE file

module PagesHelper

  def homage_link(community)
    link_text = community.homage_name.present? ? community.homage_name : community.public_name
    if(community.homage.present?)
      link_target = community.homage.id_and_link
    else
      link_target = site_index_url(:content_tag => content_tag_url_display_name(community.primary_content_tag_name))
    end
    link_to(link_text,link_target).html_safe
  end

end