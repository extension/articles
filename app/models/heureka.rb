# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Heureka < Subscriber

  def self.retrieve_faqs
    Heureka.retrieve_each { | item |  
    (item and item.valid?) ? (item.save!) : (next) 
    }
  end

  private
  def self.base_url_with_objects
    AppConfig.configtable['faq_feed']
  end  
  
  def self.class_to_create
    Faq
  end

  def self.item_name_in_response_hash
    'revision'
  end
  
end
