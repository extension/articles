# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module PreviewHelper

	def link_to_preview_tags(content_tag_array)
		linkarray = []
		content_tag_array.each do |tagname|
			linkarray << link_to(tagname, preview_tag_url(:content_tag => tagname))
		end
		return linkarray.join(' ')
	end

end