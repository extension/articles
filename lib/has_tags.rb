
module HasTags
    
    def self.included(within)
      within.class_eval { extend ClassMethods }
    end
    
    module ClassMethods
      def has_content_tags(opts ={})
        # Get options with defaults
        add_content_tags_scope(opts)
        
        # single tag scope
        add_content_tag_scope(opts)

        # any content tag scope
        add_any_content_tag_scope(opts)
        
        # all content tag scope
        add_all_content_tag_scope(opts)
      end
      
      # no options currently
      # NOTE! NOTE! NOTE! this scope is designed to do an AND of all the tags
      def add_content_tags_scope(opts={})
  
        # Get the list that belong to the given categories.
        # If the :within option is given that means that
        # category is required.
        scope :tagged_with_content_tags, lambda { |tagliststring|
    
          includelist= Tag.castlist_to_array(tagliststring,true,false)
                                              
          if(!includelist.empty?)
            # get a list of all the id's tagged with the includelist
            includeconditions = "(tags.name IN (#{includelist.map{|tagname| "'#{tagname}'"}.join(',')})) AND (taggings.tagging_kind = #{Tagging::CONTENT}) AND (taggings.taggable_type = '#{self.name}')"
            includetaggings = Tagging.find(:all, :include => :tag, :conditions => includeconditions, :group => "taggable_id", :having => "COUNT(taggable_id) = #{includelist.size}").collect(&:taggable_id)
            taggings_we_want = includetaggings
          end

          if(!taggings_we_want.empty?)
            {:conditions => "id IN (#{taggings_we_want.join(',')})"}  
          else
            # intentionally fail the named scope.  Doing something like this means this scope should be rethought completely
            {:conditions => "1 = 0"}
          end
        }
      end
      
      def add_content_tag_scope(opts={})
        scope :tagged_with_content_tag, lambda {|tagname| 
          {:include => {:taggings => :tag}, :conditions => "tags.name = '#{Tag.normalizename(tagname)}' and taggings.tagging_kind = #{Tagging::CONTENT}"}
        }
      end
      
      def add_any_content_tag_scope(opts={})
        scope :tagged_with_any_content_tags, lambda {|tagliststring|
          includelist = Tag.castlist_to_array(tagliststring)
          includeconditions = "(tags.name IN (#{includelist.map{|tagname| "'#{tagname}'"}.join(',')})) AND (taggings.tagging_kind = #{Tagging::CONTENT}) AND (taggings.taggable_type = '#{self.name}')"
          {:joins => {:taggings => :tag}, :conditions => includeconditions}
        }
      end
        
      def add_all_content_tag_scope(opts={})    
        scope :tagged_with_all_content_tags, lambda{|tagliststring|
          includelist = Tag.castlist_to_array(tagliststring)
          includeconditions = "(tags.name IN (#{includelist.map{|tagname| "'#{tagname}'"}.join(',')}) AND (taggings.tagging_kind = #{Tagging::CONTENT}) AND (taggings.taggable_type = '#{self.name}'))"
          {:joins => {:taggings => :tag}, :conditions => includeconditions, :group => "#{self.table_name}.id", :having => "COUNT(#{self.table_name}.id) = #{includelist.size}"}
        }  
      end
      
      
      # ######
      # TODO: a bit too much repeating ourselves here
      # ######
      
      def has_shared_tags(opts ={})
        # Get options with defaults
        add_shared_tags_scope(opts)
        
        # single tag scope
        add_shared_tag_scope(opts)

        # any content tag scope
        add_any_shared_tag_scope(opts)
      end
      
      def add_shared_tags_scope(opts={})
        
        scope :tagged_with_shared_tags, lambda { |tagliststring|

          includelist= Tag.castlist_to_array(tagliststring,true,false)

          if(!includelist.empty?)
            # get a list of all the id's tagged with the includelist
            includeconditions = "(tags.name IN (#{includelist.map{|tagname| "'#{tagname}'"}.join(',')})) AND (taggings.tagging_kind = #{Tagging::SHARED}) AND (taggings.taggable_type = '#{self.name}')"
            includetaggings = Tagging.find(:all, :include => :tag, :conditions => includeconditions, :group => "taggable_id", :having => "COUNT(taggable_id) = #{includelist.size}").collect(&:taggable_id)
            taggings_we_want = includetaggings
          end

          if(!taggings_we_want.empty?)
            {:conditions => "id IN (#{taggings_we_want.join(',')})"}  
          else
            # intentionally fail the named scope.  Doing something like this means this scope should be rethought completely
            {:conditions => "1 = 0"}
          end
        }
      end
      
      def add_shared_tag_scope(opts={})
        scope :tagged_with_shared_tag, lambda {|tagname| 
          {:include => {:taggings => :tag}, :conditions => "tags.name = '#{Tag.normalizename(tagname)}' and taggings.tagging_kind = #{Tagging::SHARED}"}
        }
      end
      
      def add_any_shared_tag_scope(opts={})
        scope :tagged_with_any_shared_tags, lambda {|tagliststring|
          includelist = Tag.castlist_to_array(tagliststring)
          includeconditions = "(tags.name IN (#{includelist.map{|tagname| "'#{tagname}'"}.join(',')})) AND (taggings.tagging_kind = #{Tagging::SHARED}) AND (taggings.taggable_type = '#{self.name}')"
          {:include => {:taggings => :tag}, :conditions => includeconditions}
        }
      end
      
          
    end
end
