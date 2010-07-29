module Extension
  module HasFeeds
    
    def self.included(within)
      within.class_eval { extend ClassMethods }
    end
    
    module ClassMethods
      
      def has_feeds(opts ={})
        add_feed_scopes(opts)
      end
      
      def add_feed_scopes(opts={})
        named_scope :tagged_with_any_shared_tags, lambda {|tagliststring|
          includelist = Tag.castlist_to_array(tagliststring)
          includeconditions = "(tags.name IN (#{includelist.map{|tagname| "'#{tagname}'"}.join(',')})) AND (taggings.tag_kind = #{Tagging::SHARED}) AND (taggings.taggable_type = '#{self.name}')"
          {:include => {:taggings => :tag}, :conditions => includeconditions}
          }
      end
      
    end #module ClassMethods
  end # module HasFeeds
end # module Extension
