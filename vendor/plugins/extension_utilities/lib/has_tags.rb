module Extension
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
      end
  
      # no options currently
      # NOTE! NOTE! NOTE! this scope is designed to do an AND of all the tags or !tags passed to it
      def add_content_tags_scope(opts={})
  
        # Get the list that belong to the given categories.
        # If the :within option is given that means that
        # category is required.
        named_scope :tagged_with_content_tags, lambda { |tagliststring|
    
          (includelist,excludelist) = Tag.castlist_to_array(tagliststring,true,true)
                        
          # this is about to get a little hairy...   in the most common case - with only a list of tags that you want to find with
          # e.g. "horses" and "learning lessons", we can do this in one query
          
          # actually, no we can't because the counter sql's won't work (like .size or paginate)
          # this may be related to:
          # https://rails.lighthouseapp.com/projects/8994/tickets/2310
          
          # HOWEVER if you want to do "horses" and "!dpl" - we have to pre-query with both and then query against the id's
                        
          if(!includelist.empty?)
            # get a list of all the id's tagged with the includelist
            includeconditions = "(tags.name IN (#{includelist.map{|tagname| "'#{tagname}'"}.join(',')})) AND (taggings.tag_kind = #{Tag::CONTENT}) AND (taggings.taggable_type = '#{self.name}')"
            includetaggings = Tagging.find(:all, :include => :tag, :conditions => includeconditions, :group => "taggable_id", :having => "COUNT(taggable_id) = #{includelist.size}").collect(&:taggable_id)
          end

          if(!excludelist.empty?)
            excludeconditions = "(tags.name IN (#{excludelist.map{|tagname| "'#{tagname}'"}.join(',')})) AND (taggings.tag_kind = #{Tag::CONTENT}) AND (taggings.taggable_type = '#{self.name}')"
            excludetaggings = Tagging.find(:all, :include => :tag, :conditions => excludeconditions, :group => "taggable_id", :having => "COUNT(taggable_id) = #{includelist.size}").collect(&:taggable_id)
          end
          
          if(!includelist.empty? and !excludelist.empty?)
            taggings_we_want = includetaggings - excludetaggings
          elsif(!includelist.empty?)
            taggings_we_want = includetaggings
          elsif(!excludelist.empty?)
            taggings_we_want = excludetaggings
          else
            taggings_we_want = []
          end
          
          if(!taggings_we_want.empty?)
            {:conditions => "id IN (#{taggings_we_want.join(',')})"}  
          else
            {}
          end
        }
      end
      
      def add_content_tag_scope(opts={})
        named_scope :tagged_with_content_tag, lambda {|tagname| 
          {:include => {:taggings => :tag}, :conditions => "tags.name = '#{Tag.normalizename(tagname)}' and taggings.tag_kind = #{Tag::CONTENT}"}
        }
      end
      
      def add_any_content_tag_scope(opts={})
        named_scope :tagged_with_any_content_tags, lambda {|tagliststring|
          includelist = Tag.castlist_to_array(tagliststring)
          includeconditions = "(tags.name IN (#{includelist.map{|tagname| "'#{tagname}'"}.join(',')})) AND (taggings.tag_kind = #{Tag::CONTENT}) AND (taggings.taggable_type = '#{self.name}')"
          {:include => {:taggings => :tag}, :conditions => includeconditions}
        }
      end
          
    end
  end
end