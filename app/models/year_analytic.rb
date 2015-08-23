# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding from the eXtension Foundation
# === LICENSE:
#
#  see LICENSE file

class YearAnalytic < ActiveRecord::Base
  belongs_to :page

  URL_PAGE = 'page'
  URL_MIGRATED_WIKI = 'wiki'
  URL_OTHER = 'other'

  def set_url_type
    if(analytics_url =~ %r{^/pages/(\d+)\/})
      self.url_type = URL_PAGE
      self.url_page_id = $1
    elsif(analytics_url =~ %r{^/pages/(\d+)$})
      self.url_type = URL_PAGE
      self.url_page_id = $1
    elsif(analytics_url =~ %r{^/pages/(.+)})
      ga_url = $1
      if(!ga_url.index('?'))
        request_uri = ga_url
      elsif(ga_url[-1,1] == '?')
        request_uri = ga_url
      else
        (request_uri,blah) = ga_url.split(%r{(.+)\?})[1,2]
      end
      if(!request_uri.blank?)
        title_to_lookup = CGI.unescape(request_uri)
        if(!title_to_lookup.valid_encoding?)
          self.url_type = URL_OTHER
        else
          if title_to_lookup =~ /\/print(\/)?$/
            title_to_lookup.gsub!(/\/print(\/)?$/, '')
          end
          self.url_type = URL_MIGRATED_WIKI
          self.url_wiki_title = title_to_lookup
        end
      else
        self.url_type = URL_OTHER
      end
    end
  end

  def associate_with_page
    case self.url_type
    when URL_PAGE
      page = Page.find_by_id(self.url_page_id)
    when URL_MIGRATED_WIKI
      page = Page.find_by_title_url(self.url_wiki_title)
    else
      # nothing
    end

    if(page)
      self.update_attribute(:page_id,page.id)
      return true
    else
      return false
    end
  end

  def self.associate_with_pages
    self.all.each do |ya|
      ya.associate_with_page
    end
  end






end
