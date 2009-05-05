module Extension
  module HasCategories
    
    def self.included(within)
      within.class_eval { extend ClassMethods }
    end
    
    module ClassMethods
      
      # Decorate this class with the ability to retrieve itself from
      # the list of categories, tags and tag names.  (This rides on
      # top of the acts_as_taggable on steroids plugin and includes
      # it within this call).  By default this will add a named scope
      # called <tt>categorized</tt>:
      #
      #   class News < ActiveRecord::Base
      #     has_categories
      #   end
      #
      #   News.categorized #=> all news items
      #   News.categorized('all') #=> all news items
      #   News.categorized('horses') #=> all news items with a tag matching 'horses'
      #   News.categorized(Tag.find(:first)) #=> all news items matching this tag
      #   News.categorized('horses', Tag.find(:first)) #=> all news items matching this tag or the tag 'horses'
      #
      # You can also tell it to automatically limit the query for categories to all the
      # ones given as arguments plus another one.  For instance, when querying News
      # items you only ever want results that have the 'news' tag.  Instead of relying
      # on your callers to remember this, you can configure <tt>has_categories</tt> to
      # automatically AND the 'news' tag on every query with the <tt>:within</tt> option:
      #
      #   class News < ActiveRecord::Base
      #     has_categories :within => :news
      #   end
      #
      #   News.categorized #=> all news items matching tag 'news'
      #   News.categorized('all') #=> all news items matching tag 'news'
      #   News.categorized('horses') #=> all news items with a tag matching 'horses' and 'news'
      #   News.categorized('horses', 'personal finance') #=> all news items with a tag matching ('horses' OR 'personal finance') AND 'news'
      #
      # Providing the :within option will also override the 'all' scope:
      #
      #   News.all #=> all news items matching tag 'news'
      #
      def has_categories(opts = {})
        
        # TODO: PUll back out into models
        acts_as_taggable
        
        # Get options with defaults
        add_categories_scope({:within => nil}.merge(opts))
        add_not_categories_scope({:within => nil}.merge(opts))
        
        # Give singleton convenience methods
        extend SingletonMethods
      end
      
      def add_categories_scope(opts)
  
        # Get the list that belong to the given categories.
        # If the :within option is given that means that
        # category is required.
        named_scope :categorized, lambda { |*categories|
    
          # Normalize category objects, tag names and comma-delimited
          # tag lists to an array of tag names
          names = categories.flatten.compact.collect do |c|      
            c.kind_of?(Tag) && c.community ? c.community.tags.collect(&:to_s) : [TagList.from(c.to_s)]
          end.flatten.compact
          
          # If we're within a particular tag it means that tag must always
          # be present, so append it here.
          names << opts[:within].to_s if opts[:within]
          
          # Build SQL conditions scope
          find_options_for_better_tagged_with(names)
        }
        
        # If we have a :within scope then override klass.all to only include that category
        named_scope :all, lambda { self.find_options_for_better_tagged_with(opts[:within].to_s) } if opts[:within].to_s
        
      end
      
      def add_not_categories_scope(opts)
  
        # Get the list that belong to the given categories.
        # If the :within option is given that means that
        # category is required.
        named_scope :not_categorized, lambda { |*categories|
    
          # Normalize category objects, tag names and comma-delimited
          # tag lists to an array of tag names
          names = categories.flatten.compact.collect do |c|      
            c.kind_of?(Tag) && c.community ? c.community.tags.collect(&:to_s) : [TagList.from(c.to_s)]
          end.flatten.compact
          
          # If we're within a particular tag it means that tag must always
          # be present, so append it here.
          names << opts[:within].to_s if opts[:within]
          
          # Build SQL conditions scope
          find_options_for_better_tagged_without(names)
        }
                
      end
      
    end
    
    module SingletonMethods
      
      def find_options_for_better_tagged_with(tag_names)
      
        # tag 'all' means nothing
        tag_names = tag_names.reject { |n| n == 'all' }.uniq
      
        # If we don't have two or more tags then no need to use our custom-rolled query
        return {} if tag_names.empty?
        # return find_options_for_tagged_with(tag_names) if tag_names.size <= 1
      
        # For each tag name, get the list of taggable_ids
        ids = tag_names.collect do |name|
          tag = Tag.find_by_name(name)
          tag ? tag.taggings.find(:all, :select => "DISTINCT taggable_id", :conditions => ["taggable_type = ?", base_class.name]).collect(&:taggable_id) : []
        end
      
        # And intersect the ids since we want only those items that have ALL tags. (not ANY tags)
        tagged_ids = ids.inject { |intersections, tagged_ids| intersections & tagged_ids }
        tagged_ids.any? ?
          { :conditions => ["#{base_class.quoted_table_name}.#{base_class.primary_key} IN (?)", tagged_ids] } :
          
          # If no matches then we want no results so use an impossible query here.
          { :conditions => "#{base_class.quoted_table_name}.#{base_class.primary_key} IS NULL" }
      end
      
      def find_options_for_better_tagged_without(tag_names)
      
        # tag 'all' means nothing
        tag_names = tag_names.reject { |n| n == 'all' }.uniq
      
        # If we don't have two or more tags then no need to use our custom-rolled query
        return {} if tag_names.empty?
        # return find_options_for_tagged_with(tag_names) if tag_names.size <= 1
      
        # For each tag name, get the list of taggable_ids
        ids = tag_names.collect do |name|
          tag = Tag.find_by_name(name)
          tag ? tag.taggings.find(:all, :select => "DISTINCT taggable_id", :conditions => ["taggable_type = ?", base_class.name]).collect(&:taggable_id) : []
        end
      
        # And intersect the ids since we want only those items that have ALL tags. (not ANY tags)
        tagged_ids = ids.inject { |intersections, tagged_ids| intersections & tagged_ids }
        tagged_ids.any? ?
          { :conditions => ["#{base_class.quoted_table_name}.#{base_class.primary_key} NOT IN (?)", tagged_ids] } :
          
          # If no matches then we want no results so use an impossible query here.
          { :conditions => "#{base_class.quoted_table_name}.#{base_class.primary_key} IS NULL" }
      end
      
    end
  end
end
        