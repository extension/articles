# === COPYRIGHT:
#  Copyright (c) 2005-2011 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
class Analytic < ActiveRecord::Base
  belongs_to :page
  
  def set_page_id
    if(self.analytics_url =~ %r{^/pages/(\d+)\/})
      @page = Page.find_by_id($1)
    elsif(self.analytics_url =~ %r{^/pages/(\d+)$})
      @page = Page.find_by_id($1)
    elsif(self.analytics_url =~ %r{^/article/(\d+)})
      @page = Page.find_by_id($1)
    elsif(self.analytics_url =~ %r{^/faq/(\d+)})
      @page = Page.find_by_migrated_id($1)
    elsif(self.analytics_url =~ %r{^/events/(\d+)})
      @page = Page.find_by_migrated_id($1)
    elsif(self.analytics_url =~ %r{^/pages/(.+)})
      title_to_lookup = self.mogrify_analytics_url
      @page = Page.find_by_title_url(title_to_lookup)
    end
    
    if(@page)
      self.update_attribute(:page,@page)
    end
  end
  
  def mogrify_analytics_url
    if(self.analytics_url =~ %r{^/pages/(.+)})
      ga_url = $1
      if(!ga_url.index('?'))
        request_uri = ga_url
      elsif(ga_url[-1,1] == '?')
        request_uri = ga_url
      else
        (request_uri,blah) = ga_url.split(%r{(.+)\?})[1,2]
      end
      title_to_lookup = CGI.unescape(request_uri)
      # finding doublequoted strings, probably from the export
      title_to_lookup.gsub!('""','"')
      if title_to_lookup =~ /\/print(\/)?$/
        title_to_lookup.gsub!(/\/print(\/)?$/, '')
      end
      return title_to_lookup
    else
      return nil
    end
  end
  
end