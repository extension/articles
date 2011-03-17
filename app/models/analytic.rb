# === COPYRIGHT:
#  Copyright (c) 2005-2011 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
class Analytic < ActiveRecord::Base
  belongs_to :page
  
  before_create :set_page_id
  before_create :set_recordsignature
  
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
      self.page = @page
    end
  end
  
  
  def set_recordsignature
    self.analytics_url_hash = self.class.recordsignature(self.datalabel,self.analytics_url)
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
      if title_to_lookup =~ /\/print(\/)?$/
        title_to_lookup.gsub!(/\/print(\/)?$/, '')
      end
      return title_to_lookup
    else
      return nil
    end
  end
  
  def self.recordsignature(datalabel,url)
    Digest::SHA1.hexdigest(datalabel + ":" + url)
  end
  
  def self.find_by_recordsignature(datalabel,url)
    self.first(:conditions => {:analytics_url_hash => self.recordsignature(datalabel,url)})
  end
    
  
end