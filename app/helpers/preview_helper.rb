# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module PreviewHelper

	def link_to_preview_tags(content_tag_array, links = false)
		linkarray = []
		linkarray << '<ul class="content_tags">'
		if links
		  content_tag_array.each do |tagname|
  			linkarray << '<li>' + link_to("checklist", preview_tag_url(:content_tag => content_tag_url_display_name(tagname))) + "</li>"
  		end
	  else
	    content_tag_array.each do |tagname|
  			linkarray << "<li>" + tagname + "</li>"
  		end
  	end
  	linkarray << "</ul>"
		return linkarray
	end

end