# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module Widgets::AaeHelper
  
  def change_widget_connection_link(container,widget,label,connectaction,linkoptions = {})
    url = {:controller => '/widgets/aae', :action => :change_my_connection, :id => widget.id, :connectaction => connectaction}
    if(container == 'nointerest')
      color = 'white'
    else
      color = 'ffe2c8'
    end
    progress = "<p><img src='/images/common/ajax-loader-#{color}.gif' /> Saving... </p>"
    return link_to_remote(label, {:url => url, :loading => update_page{|p| p.replace_html(container,progress)}}, linkoptions)
  end
  
end
