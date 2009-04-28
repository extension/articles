# === COPYRIGHT:
#  Copyright (c) 2005-2008 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

# The Tag model. This model is automatically generated and added to your app if you run the tagging generator included with has_many_polymorphs.

class Tag < ActiveRecord::Base
  USER = 'user'
  SYSTEM = 'system'
  SHARED = 'shared'
 
  SPLITTER = Regexp.new(/("[^"]*")|\s+|\s*,\s*/)
  JOINER = " " 

  # If database speed becomes an issue, you could remove these validations and rescue the ActiveRecord database constraint errors instead.
  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false
  
  # Set up the polymorphic relationship.
  has_many_polymorphs :taggables, 
    :from => [:users, :communities, :institutions], 
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
    # eg. remove spaces, special characters and downcase
    def normalizename(name)
      return name.downcase.gsub(/[^a-z0-9:_-]/,'')
    end
  
  end
    
  # Tag::Error class. Raised by ActiveRecord::Base::TaggingExtensions if something goes wrong.
  class Error < StandardError
  end
  

end
