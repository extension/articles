require 'net/http'

class ExternalArticleFeed
  
  class << self
    # Import all feed content
    def retrieve_feeds  
      FeedLocation.active.collect do |feed|
        puts "Fetching articles from #{feed.uri}"
        fetch_atom_feed(feed.uri).collect do |entry|
          ExternalArticle.from_atom_entry(entry)
        end
      end      
    end

    # Parse atom feed using much the same logic as WikiFeed
    def fetch_atom_feed(full_url)
      url = URI.parse(full_url)
      # need to set If-Modified-Since
      http = Net::HTTP.new(url.host, url.port) 
      http.read_timeout = 300
      
      response = url.query.nil? ? http.get(url.path) : http.get(url.path + "?" + url.query)
      AtomEntry.entries_from_xml(response.body)
      #Atom::Feed.load_feed(URI.parse(full_url))
    end
  end
  
end
