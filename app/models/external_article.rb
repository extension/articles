# An article imported from a generic atom feed
class ExternalArticle < Article
  
  after_create :store_new_url
  # before_update :check_content
          
  # Resolve the links in this article's body and save the article
  def resolve_links!    
    self.resolve_links
    self.save
  end
  
  # Make sure incoming links that point to relative urls
  # are either made absolute if the content the point
  # to doesn't exist in pubsite or are made to point to
  # pubsite content if it has been imported.
  def resolve_links
    # Pull out each link
    self.content = self.original_content.gsub(/href="(.+?)"/) do
      
      # Pull match from regex cruft
      link_uri = $1
      full_uri = $&
      
      # Only if it's not already an extension.org url nor a fragment do
      # we want to try and resolve it
      if not (link_uri.extension_url? or link_uri.fragment_only_url?)
        begin
          # Calculate the absolute path to the original location of this link
          uri = link_uri.relative_url? ?
            URI.parse(self.original_url).swap_path!(link_uri) :
            URI.parse(link_uri)
          
          # See if we've imported the original article.
          new_link_uri = (existing_article = Article.find(:first, :select => 'url', :conditions => { :original_url => uri.to_s })) ?
            existing_article.url : nil
          
          if new_link_uri
            # found published article, replace link
            result = "href=\"#{new_link_uri}\""
          elsif link_uri.relative_url?
            # link was relative and no published article found
            result = "name=\"not-published-#{uri.to_s}\""
          else
            # appears to be an ext. ref, just pass it
            result = "href=\"#{uri.to_s}\""
          end
        rescue
          result = full_uri
        end #rescue block
      else
        result = full_uri
      end #if
            
      result
    end #do
  end
  
  def id_and_link
    default_url_options[:host] = AppConfig.configtable['url_options']['host']
    default_url_options[:port] = AppConfig.get_url_port
    article_page_url(:id => self.id)
  end
  
  # used to create the urls for the page -eg. article_page_url
  def self.representative_field
    'id'
  end
  
  def self.page
    'article'
  end
  
  
  
  private
  
  # Can only be done after we have a pk
  def store_new_url
    self.url = article_page_url(:id => self.id)
    logger.debug('worky store_url')
    self.save
  end
    
  def check_content
    if self.original_content_changed?
      self.original_content = self.original_content.gsub(/<!\[CDATA\[/, '').gsub(/\]\]>/, '')
      self.content = nil
      logger.debug('worky check_content')
    end
  end
  
  def store_content #ac
    self.original_content = self.original_content.gsub(/<!\[CDATA\[/, '').gsub(/\]\]>/, '')
    logger.debug('worky store_content')
    self.save
  end
  
end
