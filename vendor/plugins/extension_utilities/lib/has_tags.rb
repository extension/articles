module Extension
  module HasTags
    
    def self.included(within)
      within.class_eval { extend ClassMethods }
    end
    
    module ClassMethods
      def has_content_tags(opts ={})
        # Get options with defaults
        add_content_tags_scope(opts)
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
          
          # HOWEVER if you want to do "horses" and "!dpl" - we have to pre-query with both and then query against the id's
                        
          if(!includelist.empty?)
            if(excludelist.empty?)
              # yay!
              conditions = []
              conditions << "(tags.name IN (#{includelist.map{|tagname| "'#{tagname}'"}.join(',')}))"
              needed_item_count = includelist.size
              conditions << "(taggings.tag_kind = #{Tag::CONTENT})"
              {:select => "#{base_class.quoted_table_name}.*, COUNT(taggings.taggable_id) as matchingtotal", :joins => { :taggings => :tag}, :conditions => conditions.join(' AND '), :group => "taggings.taggable_id", :having => "matchingtotal = #{needed_item_count}"}
            else
              # damn
              # get a list of all the id's tagged with the includelist
              includeconditions = "(tags.name IN (#{includelist.map{|tagname| "'#{tagname}'"}.join(',')})) AND (taggings.tag_kind = #{Tag::CONTENT}) AND (taggings.taggable_type = '#{self.name}')"
              excludeconditions = "(tags.name IN (#{excludelist.map{|tagname| "'#{tagname}'"}.join(',')})) AND (taggings.tag_kind = #{Tag::CONTENT}) AND (taggings.taggable_type = '#{self.name}')"
              
              includetaggings = Tagging.find(:all, :include => :tag, :conditions => includeconditions, :group => "taggable_id", :having => "COUNT(taggable_id) = #{includelist.size}").collect(&:taggable_id)
              excludetaggings = Tagging.find(:all, :include => :tag, :conditions => excludeconditions, :group => "taggable_id", :having => "COUNT(taggable_id) = #{includelist.size}").collect(&:taggable_id)
              
              taggings_we_want = includetaggings - excludetaggings
              {:conditions => "id IN (#{taggings_we_want.join(',')})"}
            end
          elsif(!excludelist.empty?)
            # excludes only
            conditions = []
            conditions << "(tags.name NOT IN (#{includelist.map{|tagname| "'#{tagname}'"}.join(',')}))"
            needed_item_count = excludelist.size
            conditions << "(taggings.tag_kind = #{Tag::CONTENT})"
            {:select => "#{base_class.quoted_table_name}.*, COUNT(taggings.taggable_id) as matchingtotal", :joins => { :taggings => :tag}, :conditions => conditions.join(' AND '), :group => "taggings.taggable_id", :having => "matchingtotal = #{needed_item_count}"}
          else
            {}
          end
        }
      end
    end
  end
end