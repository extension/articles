# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module TaggingScopes
  def self.included(base)
    base.class_eval do
      named_scope :tagged_with_all, lambda{|taglist|
        includelist= Tag.castlist_to_array(taglist,true,false)
        {:joins => [:tags], :conditions => "tags.name IN (#{includelist.map{|tagname| "'#{tagname}'"}.join(',')})", :group => "#{self.table_name}.id", :having => "COUNT(#{self.table_name}.id) = #{includelist.size}"}
      }
    end
  end
end
