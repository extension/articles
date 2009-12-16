# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

# a convenience class for parsing an atom feed into items useful for Article-like display

class PreviewArticle
  
  attr_accessor :atom_url, :atom_url_content, :atom_source
  attr_accessor :title, :original_content, :updated_at, :published_at, :url, :author, :is_dpl
  attr_accessor :content_buckets, :content_tags
  
  # ATOM SOURCES
  UNKNOWN = 0
  EXTENSIONORG_WIKI = 1
  OTHER_SOURCE = 2
  
  def self.new_from_extensionwiki_page(pagetitle)
    article = PreviewArticle.new
    article.atom_url = AppConfig.configtable['content_feed_wiki_previewpage'] + CGI::escape(pagetitle)
    article.atom_source = EXTENSIONORG_WIKI
    article.parse_atom_content
    return article
  end

  #
  # parses original_content with Nokogiri
  #
  def parsed_content
    if(@parsed_content.nil?)
      @parsed_content = Nokogiri::HTML::DocumentFragment.parse(self.original_content)
    end
    @parsed_content
  end
  
  def content
    case self.atom_source
    when EXTENSIONORG_WIKI
      self.convert_wiki_links
      return @converted_content.to_html
    else
      return self.original_content
    end

  end
  
  #
  # puts together a hash of the <a href>'s in the content
  # [href] = link text
  #
  def content_links
    if(@content_links.nil?)
      @content_links = {}
      self.parsed_content.css('a').each do |anchor|
        if(anchor['href'])
          @content_links[anchor['href']] = anchor.content
        end
      end
    end
    @content_links
  end
  
  def converted_links
    if(@converted_links.nil?)
      @converted_links = {}
      self.convert_links if(@converted_content.nil?)
      @converted_content.css('a').each do |anchor|
        if(anchor['href'])
          @converted_links[anchor['href']] = anchor.content
        end
      end
    end
    @converted_links
  end
  
  # 
  # converts relative hrefs and hrefs that refer to the feed source
  # to something relative to /preview/pages/
  #
  def convert_wiki_links
    wikisource_uri = URI.parse(AppConfig.configtable['content_feed_wiki_previewpage'])
    host_to_make_relative = wikisource_uri.host
      
    if(@converted_content.nil?)
      @converted_content = Nokogiri::HTML::DocumentFragment.parse(self.original_content)
    end
    
    convert_count = 0
    @converted_content.css('a').each do |anchor|
      if(anchor['href'])
        if(anchor['href'] =~ /^\#/) # in-page anchor, don't change
          newhref = anchor['href']
          next
        end
        # make sure the URL is valid format
        begin
          original_uri = URI.parse(anchor['href'])
        rescue
          anchor.set_attribute('href', '')
          anchor.set_attribute('class', 'bad_link')
          anchor.set_attribute('title', 'Bad Link, Please edit or remove it.')
          next
        end
        
        if(original_uri.scheme.nil?)
          if(original_uri.path =~ /^\/wiki\/(.*)/)  # does path start with '/wiki'? - then strip it out
            newhref =  '/preview/pages/' + $1
          else
            newhref =  '/preview/pages/'+ original_uri.path
          end
          convert_count += 1              
        elsif((original_uri.scheme == 'http' or original_uri.scheme == 'https') and original_uri.host == host_to_make_relative)
          # make relative
          if(original_uri.path =~ /^\/wiki\/(.*)/) # does path start with '/wiki'? - then strip it out
            newhref =  '/preview/pages/' + $1
          else
            newhref =  '/preview/pages/'+ original_uri.path
          end
          convert_count += 1              
        else
          newhref = anchor['href']
        end
        anchor.set_attribute('href',newhref)
      end
    end
    convert_count
  end
  
  def set_content_tags(tagarray)
    namearray = []
    tagarray.each do |tag_name|
      normalized_tag_name = Tag.normalizename(tag_name)
      next if Tag::BLACKLIST.include?(normalized_tag_name)
      namearray << normalized_tag_name
    end
    
    taglist = Tag.find(:all, :conditions => "name IN (#{namearray.map{|n| "'#{n}'"}.join(',')})")
    self.content_tags = taglist
  end

  def put_in_buckets(categoryarray)
    namearray = []
    categoryarray.each do |name|
      namearray << ContentBucket.normalizename(name)
    end
    
    buckets = ContentBucket.find(:all, :conditions => "name IN (#{namearray.map{|n| "'#{n}'"}.join(',')})")
    self.content_buckets = buckets
  end
    
  def parse_atom_content()
     # will raise errors on failure, sets self.atom_content
     self.fetch_url_content

     atom_entries =  Atom::Feed.load_feed(self.atom_url_content).entries
     if(atom_entries.blank?)
       raise ContentRetrievalError, "No atom entries found in feed."
     end
      
     # we are just going to take the first entry
     parsed_atom_entry = atom_entries[0]       
    
     if parsed_atom_entry.updated.nil?
       self.updated_at = Time.now.utc
     else
       self.updated_at = parsed_atom_entry.updated
     end

     if parsed_atom_entry.published.nil?
       self.published_at = self.updated_at
     else
       self.published_at = parsed_atom_entry.published
     end

     self.title = parsed_atom_entry.title
     self.url = parsed_atom_entry.links[0].href if self.url.blank?
     self.author = parsed_atom_entry.authors[0].name
     self.original_content = parsed_atom_entry.content.to_s

     # flag as dpl
     if !parsed_atom_entry.categories.blank? and parsed_atom_entry.categories.map(&:term).include?('dpl')
       self.is_dpl = true
     end

      if(!parsed_atom_entry.categories.blank?)
       self.set_content_tags(parsed_atom_entry.categories.map(&:term))
       self.put_in_buckets(parsed_atom_entry.categories.map(&:term))    
     end
     
   end
  
  
   # returns a block of content read from a file or a URL, does not parse
   def fetch_url_content
     urlcontent = ''
     # figure out if this is a file url or a regular url and behave accordingly
     fetch_uri = URI.parse(self.atom_url)
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
         self.atom_url_content  = response.body
       else
         raise ContentRetrievalError, "Fetch URL Content:  Fetch from #{self.atom_url} failed: #{response.code}/#{response.message}"          
       end    
     else # unsupported URL scheme
       raise ContentRetrievalError, "Fetch URL Content:  Unsupported scheme #{feed_url}"          
     end

     return self.atom_url_content 
   end
  
     
  
end