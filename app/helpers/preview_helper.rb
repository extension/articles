# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
# 
#  see LICENSE file

module PreviewHelper

	def link_to_preview_tags(content_tag_array, links = false)
		linkarray = []
		linkarray << '<ul class="content_tags">'
		if links
		  content_tag_array.each do |tagname|
  			linkarray << '<li>' + link_to("#{tagname} checklist", preview_tag_url(:content_tag => content_tag_url_display_name(tagname))).html_safe + "</li>"
  		end
	  else
	    content_tag_array.each do |tagname|
  			linkarray << "<li>" + tagname + "</li>"
  		end
  	end
  	linkarray << "</ul>"
		return linkarray.join.html_safe
	end

end