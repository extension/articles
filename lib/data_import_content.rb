# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
module DataImportContent
  
  # returns a block of content read from a file or a URL, does not parse
  def fetch_url_content(feed_url)
    urlcontent = ''
    # figure out if this is a file url or a regular url and behave accordingly
    fetch_uri = URI.parse(feed_url)
    if(fetch_uri.scheme.nil?)
      raise ContentRetrievalError, "Fetch URL Content:  Invalid URL: #{feed_url}"
    elsif(fetch_uri.scheme == 'file')
      if File.exists?(fetch_uri.path)
        File.open(loadfromfile) { |f|  urlcontent = f.read }          
      else
        raise ContentRetrievalError, "Fetch URL Content:  Invalid file #{fetch_uri.path}"        
      end
    elsif(fetch_uri.scheme == 'http' or fetch_uri.scheme == 'https')  
      # TODO: need to set If-Modified-Since
      http = Net::HTTP.new(fetch_uri.host, fetch_uri.port) 
      http.read_timeout = 300
      response = fetch_uri.query.nil? ? http.get(fetch_uri.path) : http.get(fetch_uri.path + "?" + fetch_uri.query)
      case response
      # TODO: handle redirection?
      when Net::HTTPSuccess
        urlcontent = response.body
      else
        raise ContentRetrievalError, "Fetch URL Content:  Fetch from #{parse_url} failed: #{response.code}/#{response.message}"          
      end    
    else # unsupported URL scheme
      raise ContentRetrievalError, "Fetch URL Content:  Unsupported scheme #{feed_url}"          
    end
    
    return urlcontent
  end
  
  
  def build_feed_url(feed_url,refresh_since,xmlschematime=true)
    fetch_uri = URI.parse(feed_url)
    if(fetch_uri.scheme.nil?)
      raise ContentRetrievalError, "Build Feed URL:  Invalid URL: #{feed_url}"
    elsif(fetch_uri.scheme == 'file')
      return "#{feed_url}"
    else
      if(xmlschematime)
        return "#{feed_url}#{refresh_since.xmlschema}"
      else
        return "#{feed_url}/#{refresh_since.year}/#{refresh_since.month}/#{refresh_since.day}/#{refresh_since.hour}/#{refresh_since.min}/#{refresh_since.sec}"
      end
    end
  end

end