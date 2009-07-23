# === COPYRIGHT:
#  Copyright (c) 2005-2008 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

# The Tag model. This model is automatically generated and added to your app if you run the tagging generator included with has_many_polymorphs.

class Tag < ActiveRecord::Base
  GENERIC = 0  # table defaults
  USER = 1
  SHARED = 2
  CONTENT = 3
  
  # special class of 'all' for caching purposes
  ALL = 42  # the ultimate answer, of course
 
  SPLITTER = Regexp.new(/\s*,\s*/)
  JOINER = "," 
  
  # terms that can't be used as tags
  BLACKLIST = ['all']
  
  # terms that can be used as tags, but have special meaning
  CONTENTBLACKLIST = ['article', 'contents', 'dpl', 'events', 'faq', 'feature',
                    'highlight', 'homage', 'youth', 'learning lessons',
                    'learning lessons home', 'main', 'news', 'beano']

  # If database speed becomes an issue, you could remove these validations and rescue the ActiveRecord database constraint errors instead.
  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false
  
  # Set up the polymorphic relationship.
  has_many_polymorphs :taggables, 
    :from => [:users, :communities, :institutions, :articles, :faqs, :events, :submitted_questions, :advertisements], 
    :through => :taggings, 
    :dependent => :destroy,
    :as => :tag,
    :skip_duplicates => false, 
    :parent_extend => proc {
      # Defined on the taggable models, not on Tag itself. Return the tagnames associated with this record as a string.
      def to_s
        self.map(&:name).sort.join(Tag::JOINER)
      end
    }
        
  # Callback to normalize the tagname before saving it. 
  def before_save
    self.name = self.class.normalizename(self.name)
  end
  
  named_scope :community_content_tags, {:include => :taggings, :conditions => "taggings.tag_kind = #{Tag::CONTENT} and taggable_type = 'Community'"}
  named_scope :content_tags, {:include => :taggings, :conditions => "taggings.tag_kind = #{Tag::CONTENT}"}
  
  # TODO: review.  This is kind of a hack that might should be done differently
  def content_community
    communities.first(:include => :taggings, :conditions => "taggings.tag_kind = #{Tag::CONTENT}")
  end

  # normalize tag names 
  # convert whitespace to single space, underscores to space, yank everything that's not alphanumeric : - or whitespace (which is now single spaces)   
  def self.normalizename(name)
    # make an initial downcased copy - don't want to modify name as a side effect
    returnstring = name.downcase
    # now, use the replacement versions of gsub and strip on returnstring
    returnstring.gsub!('_',' ')
    returnstring.gsub!(/[^\w\s:-]/,'')
    returnstring.gsub!(/\s+/,' ')
    returnstring.strip!
    returnstring
  end

  def self.castlist_to_array(obj,normalizestring=true,processnots=false)      
    returnarray = []
    if(processnots)
      returnnotarray = []
    end 
    
    case obj
      when Array
        obj.each do |item|
          case item
            when /^\d+$/, Fixnum then returnarray << Tag.find(item).name # This will be slow if you use ids a lot.
            when Tag then returnarray << item.name
            when String                
              if(processnots and item.starts_with?('!'))
                returnnotarray << (normalizestring ? Tag.normalizename(item) : item.strip)
              else
                returnarray << (normalizestring ? Tag.normalizename(item) : item.strip)
              end
            else
              raise "Invalid type"
          end
        end              
      when String          
        obj.split(Tag::SPLITTER).each do |tag_name| 
          if(!tag_name.empty?)
            if(processnots and tag_name.starts_with?('!'))
              returnnotarray << (normalizestring ? Tag.normalizename(tag_name) : tag_name.strip)
            else
              returnarray << (normalizestring ? Tag.normalizename(tag_name) : tag_name.strip)
            end
          end
        end
      else
        raise "Invalid object of class #{obj.class} as tagging method parameter"
    end
    
    returnarray.flatten!
    returnarray.compact!
    returnarray.uniq!
    
    
    if(processnots)
      returnnotarray.flatten!
      returnnotarray.compact!
      returnnotarray.uniq!
      return [returnarray,returnnotarray]
    else
      return returnarray
    end
  end
    
    
  # Tag::Error class. Raised by ActiveRecord::Base::TaggingExtensions if something goes wrong.
  class Error < StandardError
  end
  

end
