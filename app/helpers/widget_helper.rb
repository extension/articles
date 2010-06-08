# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module WidgetHelper
  
  def image_upload_capable(fingerprint)
    return false if !widget = Widget.find_by_fingerprint(fingerprint)
    (widget.upload_capable == true) ? (return true) : (return false)
  end
  
end
