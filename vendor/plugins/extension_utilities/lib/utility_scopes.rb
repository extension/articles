module Extension
  module UtilityScopes
    
    def self.included(within)
      
      # Directly add some useful named scopes
      within.class_eval do
                
        # Allow Model.all.limit & Model.all.limit(5)
        named_scope :limit, lambda { |*limit|
          { :limit => limit.flatten.first || (defined?(per_page) ? per_page : 10) }
        }
      end
    end
  end
end