module Extension
  module Ordered
    
    def self.included(within)
      within.class_eval { extend ClassMethods }
    end
    
    module ClassMethods
      
      # Decorate this class with the ability to order itself in queries
      # either from a given parameter or from its default ordering:
      #
      #   class News < ActiveRecord::Base
      #     ordered_by :orderings => {'Most Useful' => 'average_ranking DESC','Newest to oldest'=> 'heureka_published_at DESC'},
      #                :default => "heureka_published_at DESC"
      #   end
      #
      #   News.ordered #=> all news items ordered by "heureka_published_at DESC"
      #   News.ordered('average_ranking ASC') #=> all news items ordered by "average_ranking ASC"
      #   News.orderings #=> {'Most Useful' => 'average_ranking DESC','Newest to oldest'=> 'heureka_published_at DESC'}
      #   News.default_ordering #=> "heureka_published_at DESC"
      #
      def ordered_by(opts = {})
        
        # Get options with defaults
        opts = {:orderings => {}, :default => 'id ASC'}.merge(opts)
        
        # Add named scope
        named_scope :ordered, lambda { |*order| { :order => order.blank? ? self.default_ordering : order } }
        
        # Give the class it's convenience "orderings" and "default_ordering" accessors
        metaclass.instance_eval do
          define_method(:orderings) { opts[:orderings] }
          define_method(:default_ordering) { opts[:default] }
        end
      end
      
      private
      
      def metaclass; class << self; self end; end
    end
  end
end
        