# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'rexml/document'

class Faq < ActiveRecord::Base
  include ActionController::UrlWriter  # so that we can generate URLs out of the model
  # currently, no need to cache, we don't fulltext search tags
  # has_many :cached_tags, :as => :tagcacheable
    
  #--- New stuff
  has_content_tags
  ordered_by :orderings => {'Newest to oldest'=> 'heureka_published_at DESC'},
             :default => "#{quoted_table_name}.heureka_published_at DESC"
  
  has_many :expert_questions
  
  PUBLISHED = "published"
  UNPUBLISHED = "unpublished"
  
  def validate_on_create
    if id.nil? || question.nil? || answer.nil? || status.nil?
      errors.add_to_base("Faq does not have all of tThe required fields.")
    end
  end
  
  def validate_on_update
    if id.nil? || question.nil? || answer.nil? || status.nil?
      errors.add_to_base("Faq does not have all of the required fields.")
    end
  end

  #creates or updates faqs based on the published faqs fed in from the internal faq tool
  #Only updated published faqs who have been updated since last pull of faqs get pulled in to the external site.
  #The published faqs that have already been pulled into the app in the past from the internal faq tool 
  #do not get pulled in if there have been no updates to them.
  #Faqs that have been unpublished in the internal faq tool since last pull will be deleted.
  def self.from_hash(hash)
    if item = Faq.find_by_id(hash['question_id'])
      if hash['status'].strip == UNPUBLISHED
        item.destroy
        return nil
      end
    else
      if hash['status'].strip == UNPUBLISHED
        return nil
      else
        item = Faq.new
      end
    end
    item.taggings.each { |t| t.destroy }
    item.tag_list = []
    hash.keys.each { | key | 
      item.set_attribute(key, hash[key]) 
    }
    assign_tags(item )
    item.save
    item
  end
  
  def id_and_link
    default_url_options[:host] = AppConfig.configtable['url_options']['host']
    default_url_options[:port] = AppConfig.get_url_port
    faq_page_url(:id => self.id.to_s)
  end
  
  def to_atom_entry
    xml = Builder::XmlMarkup.new(:indent => 2)
    
    xml.entry do
      xml.title(self.question, :type => 'html')
      xml.content(self.answer, :type => 'html')
      
      if self.categories
        self.categories.split(',').each do |cat|
          xml.category "term" => cat  
        end
      end
      
      xml.author { xml.name "Contributors" }
      xml.id(self.id_and_link)
      xml.link(:rel => 'alternate', :type => 'text/html', :href => self.id_and_link)
      xml.updated self.heureka_published_at.atom
    end
  end  
  
  def set_attribute(attribute, value)
    case attribute
      when 'updated'
        self.heureka_published_at = value
      when 'question_id'
        self.id = value
      when 'saved_names'
        handle_saved_names(attribute, value)
      when 'reference_names'
        handle_reference_names(attribute, value)
      when 'tags'
        self.categories = value.strip
        #add tags!
        
      #when 'categories'
      #  
      #  self.send("#{attribute}=", value.strip) if self.respond_to?(attribute)
      else
        self.send("#{attribute}=", value.strip) if self.respond_to?(attribute) 
    end
  end

  # needed for thread relink magic
  def self.find_by_title(title)
    return self.find_by_question(title)
  end
  
  #Stuff for use in pages
  def published_at
    heureka_published_at
  end
  def self.representative_field
    'id'
  end
  def self.page
    'faq'
  end
  def title
    question
  end  
  
  private
  
  #this handles the qualifiers for the faqs being fed in
  def handle_saved_names(attribute, value)
    if !value || !value['saved_name']
      return
    end
    only_one_saved_name = (value['saved_name'].class != Array)

    if only_one_saved_name
      if value['saved_name']['qualifier_name'] && value['saved_name']['saved_options']
        set_qualifier_property(value['saved_name']['qualifier_name'], value['saved_name']['saved_options'])
      end
    else
      value['saved_name'].each { | qualifier | set_qualifier_property(qualifier['qualifier_name'], qualifier['saved_options']) unless (!qualifier['qualifier_name'] || !qualifier['saved_options']) }
    end
  end
  
  private
  def handle_reference_names(attribute, value)
    if !value || !value['reference_name']
      return
    end
    only_one_reference_name = (value['reference_name'].class != Array)
    
    if only_one_reference_name
      if value['reference_name']['ref_name'] && value['reference_name']['ref_options']
        set_qualifier_property(value['reference_name']['ref_name'], value['reference_name']['ref_options'])
      end
    else
      value['reference_name'].each { |ref| set_qualifier_property(ref['ref_name'],ref['ref_options']) unless (!ref['ref_name'] || !ref['ref_options']) }
    end
  end
  
  def set_qualifier_property(qualifier_name, value)
    method_name = method_name_for(qualifier_name.strip)
    self.send(method_name, value.strip)
  end
  
  
  def method_name_for(qualifier_name)
    property_name = qualifier_name.gsub(' ', '').underscore.pluralize
    "#{property_name}="
  end
  
  
  def self.assign_tags(faq)
    faq.tag_list.add(*faq.categories.split(',')) if faq.categories
  end
  
end
