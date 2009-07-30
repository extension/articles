# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE


module HasStates
  
  def self.included(within)
    
    # Add some convenience scopes
    within.class_eval do
      
      # Get all of this model with the given states (+ national level events)
      named_scope :in_states, lambda { |*states|
        
        states = states.flatten.compact.uniq.reject { |s| s.blank? }
        return {} if states.empty?
        conditions = states.collect { |s| sanitize_sql_array(["state_abbreviations like ?", "%#{s.to_s.upcase}%"]) }.join(' AND ')
        {:conditions => "#{conditions} OR (state_abbreviations = '' and coverage = 'National')"}
      }
    end
  end
  
  def states
    clean_abbreviations.collect { | abbrev | Location.find_by_abbreviation(abbrev).name }
  end

  def state_names
    states.join(', ')
  end

  def state_abbreviations=(new_value)
    super(clean_abbreviations(new_value).join(' '))
  end

  def validate_state_abbreviations
    clean_abbreviations.each do | abbrev |
      errors.add(:state_abbreviations, "'#{abbrev}' is not a valid State abbreviation")  unless State[abbrev]
    end
  end

  def sort_states
    self.state_abbreviations = clean_abbreviations.sort.join(' ')
  end


  private
  def clean_abbreviations(abbreviations_string = self.state_abbreviations)
    return [] unless abbreviations_string
    abbreviations_string.split(/ |;|,/).compact.delete_if { | each | each.blank? }.collect { | each | each.upcase }.uniq
  end  

end
