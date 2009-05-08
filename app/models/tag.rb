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

  # If database speed becomes an issue, you could remove these validations and rescue the ActiveRecord database constraint errors instead.
  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false
  
  # Set up the polymorphic relationship.
  has_many_polymorphs :taggables, 
    :from => [:users, :communities, :institutions, :articles, :faqs, :events, :submitted_questions], 
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
  
  class << self
  
    # normalize tag names 
    # convert whitespace to single space, underscores to space, yank everything that's not alphanumeric : - or whitespace (which is now single spaces)   
    def normalizename(name)
      # make an initial downcased copy - don't want to modify name as a side effect
      returnstring = name.downcase
      # now, use the replacement versions of gsub and strip on returnstring
      returnstring.gsub!('_',' ')
      returnstring.gsub!(/[^\w\s:-]/,'')
      returnstring.gsub!(/\s+/,' ')
      returnstring.strip!
      returnstring
    end
  end
    
  # Tag::Error class. Raised by ActiveRecord::Base::TaggingExtensions if something goes wrong.
  class Error < StandardError
  end
  

end
