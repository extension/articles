# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class ContentBucket < ActiveRecord::Base
  has_many :article_buckets
  has_many :articles, :through => :article_buckets

  SPLITTER = Regexp.new(/\s*,\s*/)
  JOINER = "," 

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
    
end
