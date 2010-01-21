# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class ContentLink < ActiveRecord::Base
  belongs_to :content, :polymorphic => true # this is for published items to associate links to that published item
  has_many :linkings
  #has_many :linkedcontentitems, :through => :linkings, :source => :contentitem # this is the association for items that link to this item
  
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
  
  def href_url
    case self.linktype
    when WANTED
      return ''
    when INTERNAL
      self.content.href_url
    when EXTERNAL
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
    
    content_link = self.new(:content => content, :original_url => original_uri.to_s, :original_fingerprint => Digest::SHA1.hexdigest(original_uri.to_s))
    content_link.source_host = original_uri.host
    content_link.linktype = INTERNAL
    
    # set host and path - mainly just for aggregation purposes
    content_link.host = original_uri.host
    content_link.path = original_uri.path
    content_link.save
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
    
    # TODO - handle special case of File: and Image: links
    
    # is this a relative url? (no scheme/no host)- so attach the source_host and http
    # to it, to see if that matches an original URL that we have
    original_uri.host = source_host if(original_uri.host.blank?)
    original_uri.scheme = 'http' if(original_uri.scheme.blank?)
    
    # for comparison purposes - we need to drop the fragment - the caller is going to
    # need to maintain the fragment when they get an URI back from this class.
    if(!original_uri.fragment.blank?)
      original_uri.fragment = ''
    end
    
    # we'll keep the path around - but we might should drop them for CoP wiki sourced articles

    if(content_link = self.find_by_original_fingerprint(Digest::SHA1.hexdigest(original_uri.to_s)))
      return content_link
    end
    
    # create it - if host matches source_host and we want to identify this as "wanted" - then make it wanted else - call it external
    # the reason for the make_wanted_if_source_host_match parameter is I imagine we are going to have a situation with 
    # some feed provider where they want to link back to their own content - and we shouldn't necessarily force that link to be relative
    content_link = self.new(:original_url => original_uri.to_s, :original_fingerprint => Digest::SHA1.hexdigest(original_uri.to_s), :source_host => source_host)
    if(original_uri.host == source_host and make_wanted_if_source_host_match)
      content_link.linktype = WANTED
    else
      content_link.linktype = EXTERNAL
    end
    
    # set host and path - mainly just for aggregation purposes
    content_link.host = original_uri.host
    content_link.path = original_uri.path
    content_link.save
    return content_link        
  end
  
end
  
  
