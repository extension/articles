# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class ContentLink < ActiveRecord::Base
  belongs_to :content, :polymorphic => true # this is for published items to associate links to that published item
  has_many :linkings
  
  validates_presence_of :original_fingerprint, :linktype
  
  # this is the association for items that link to this item
  has_many_polymorphs :contentitems, 
    :from => [:articles], 
    :through => :linkings, 
    :dependent => :destroy,
    :as => :content_link,
    :skip_duplicates => false
  
  # link types
  WANTED = 1
  INTERNAL = 2
  EXTERNAL = 3
  MAILTO = 4
  
  
  def href_url
    case self.linktype
    when WANTED
      return ''
    when INTERNAL
      self.content.href_url
    when EXTERNAL
      self.original_url
    when MAILTO
      self.original_url
    end
  end
  
  def self.create_from_content(content)
    if(content.original_url.blank?)
      return nil
    end

    # make sure the URL is valid format
    begin
      original_uri = URI.parse(content.original_url)
    rescue
      return nil
    end
    
    if(content_link = self.find_by_original_fingerprint(Digest::SHA1.hexdigest(CGI.unescape(original_uri.to_s))))
      # this was a wanted link - we need to update the link now - and kick off the process of updating everything
      # that links to this piece of content.
      content_link.update_attributes(:content => content, :linktype => INTERNAL)
      content_link.contentitems.each do |linked_content_item|
        linked_content_item.store_content # parses links and images again and saves it.
      end
    else    
      content_link = self.new(:content => content, :original_url => CGI.unescape(original_uri.to_s), :original_fingerprint => Digest::SHA1.hexdigest(CGI.unescape(original_uri.to_s)))
      content_link.source_host = original_uri.host
      content_link.linktype = INTERNAL
    
      # set host and path - mainly just for aggregation purposes
      if(!original_uri.host.blank?)
        content_link.host = original_uri.host
      end
      if(!original_uri.path.blank?)
        content_link.path = CGI.unescape(original_uri.path)
      end
      content_link.save
    end
    return content_link
  end
  
  # this is meant to be called when parsing a piece of content for items it links to itself.
  def self.find_or_create_by_linked_url(linked_url,source_host,make_wanted_if_source_host_match = true)
    # make sure the URL is valid format
    begin
      original_uri = URI.parse(linked_url)
    rescue
      return nil
    end
    
    # is this a /wiki/Image:blah or /wiki/File:blah link? - then return nothing - it's ignored
    if(original_uri.path =~ /^\/wiki\/File:.*/ or original_uri.path =~ /^\/wiki\/Image:(.*)/)
      return ''
    end
    
    # is this a relative url? (no scheme/no host)- so attach the source_host and http
    # to it, to see if that matches an original URL that we have
    if(!original_uri.is_a?(URI::MailTo))
      original_uri.host = source_host if(original_uri.host.blank?)
      original_uri.scheme = 'http' if(original_uri.scheme.blank?)
    end
    
    # for comparison purposes - we need to drop the fragment - the caller is going to
    # need to maintain the fragment when they get an URI back from this class.
    if(!original_uri.fragment.blank?)
      original_uri.fragment = ''
    end
    
    # we'll keep the path around - but we might should drop them for CoP wiki sourced articles

    if(content_link = self.find_by_original_fingerprint(Digest::SHA1.hexdigest(CGI.unescape(original_uri.to_s))))
      return content_link
    end
    
    # create it - if host matches source_host and we want to identify this as "wanted" - then make it wanted else - call it external
    # the reason for the make_wanted_if_source_host_match parameter is I imagine we are going to have a situation with 
    # some feed provider where they want to link back to their own content - and we shouldn't necessarily force that link to be relative
    content_link = self.new(:original_url => CGI.unescape(original_uri.to_s), :original_fingerprint => Digest::SHA1.hexdigest(CGI.unescape(original_uri.to_s)), :source_host => source_host)
    if(original_uri.is_a?(URI::MailTo))
      content_link.linktype = MAILTO
    elsif(original_uri.host == source_host and make_wanted_if_source_host_match)
      content_link.linktype = WANTED
    else
      content_link.linktype = EXTERNAL
    end
    
    # set host and path - mainly just for aggregation purposes
    if(!original_uri.host.blank?)
      content_link.host = original_uri.host
    end
    if(!original_uri.path.blank?)
      content_link.path = CGI.unescape(original_uri.path)
    end
    content_link.save
    return content_link        
  end
  
end
  
  
