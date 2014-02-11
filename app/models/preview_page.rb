# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
# 
#  see LICENSE file

# a convenience class for parsing an atom feed into items useful for Article-like display

class PreviewPage
  
  attr_accessor :source, :source_id
  attr_accessor :page_source, :title, :original_content, :updated_at, :published_at, :source_url, :author, :is_dpl
  attr_accessor :content_buckets, :content_tags
  
  def self.new_from_source(source,source_id)
    page_source = PageSource.find_by_name(source)
    return nil if(page_source.blank?)
    page = PreviewPage.new
    page.source = source
    page.source_id = source_id.to_s
    page.page_source = page_source
    page.parse_atom_content
    return page
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
    # blank content check
    if(self.original_content.blank?)
      return ''
    end

    self.convert_links
    return @converted_content.to_html
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
  def convert_links
    # if no content, don't bother.
    if(self.original_content.blank?)
      return 0
    end
    
    source_uri = URI.parse(self.source_url)
    host_to_make_relative = source_uri.host
          
    if(@converted_content.nil?)
      @converted_content = Nokogiri::HTML::DocumentFragment.parse(self.original_content)
    end
    
    convert_count = 0
    @converted_content.css('a').each do |anchor|
      if(anchor['href'])
        if(anchor['href'] =~ /^\#/) # in-page anchor, don't change
          next
        end
        # make sure the URL is valid format
        begin
          original_uri = URI.parse(anchor['href'])
        rescue
          anchor.set_attribute('href', '#')
          anchor.set_attribute('class', 'bad_link')
          anchor.set_attribute('title', 'Bad Link, Please edit or remove it.')
          next
        end
        
        if(original_uri.scheme.nil?)
          if(original_uri.path =~ /^\/wiki\/(.*)/)  # does path start with '/wiki'? - then strip it out
            # check to see if this is a Category:blah link
            title = $1
            if(title =~ /Category\:(.+)/)
              newhref = "/preview/showcategory/" + $1
            else
              newhref =  '/preview/pages/' + title
            end
          else
            if(self.source == 'copwiki')
              newhref =  '/preview/pages/' + original_uri.path
            else
              # tease an id out of the href
              target_id = original_uri.path.gsub(source_uri.path.gsub(self.source_id,''),'')
              if(target_id != original_uri.path)
                newhref = "/preview/page/#{self.source}/#{target_id}"
              else
                anchor.set_attribute('href', '#')
                anchor.set_attribute('class', 'warning_link')
                anchor.set_attribute('title', 'Relative link, unable to show in preview')
                next               
              end                    
            end
          end
          # attach the fragment to the end of it if there was one
          if(!original_uri.fragment.blank?)
            newhref += "##{original_uri.fragment}"
          end
          anchor.set_attribute('href',newhref)
          convert_count += 1              
        elsif((original_uri.scheme == 'http' or original_uri.scheme == 'https') and original_uri.host == host_to_make_relative)
          # make relative
          if(original_uri.path =~ /^\/wiki\/(.*)/) # does path start with '/wiki'? - then strip it out
            newhref =  '/preview/pages/' + $1
          else
            if(self.source == 'copwiki')
              newhref =  '/preview/pages/' + original_uri.path
            else
              # tease an id out of the href
              target_id = original_uri.path.gsub(source_uri.path.gsub(self.source_id,''),'')
              if(target_id != original_uri.path)
                newhref = "/preview/page/#{self.source}/#{target_id}"
              else
                anchor.set_attribute('href', original_uri.to_s)
                anchor.set_attribute('class', 'warning_link')
                anchor.set_attribute('title', 'Unable to handle in preview')
                next               
              end      
            end            
          end
          
          # attach the fragment to the end of it if there was one
          if(!original_uri.fragment.blank?)
            newhref += "##{original_uri.fragment}"
          end
          anchor.set_attribute('href',newhref)
          convert_count += 1              
        end
      end # anchor had an href attribute
    end # loop through the anchor tags
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
    parsed_atom_entry = page_source.atom_page_entry(self.source_id)
    

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
     self.source_url = parsed_atom_entry.links[0].href if self.source_url.blank?
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
  
  
     
  
end