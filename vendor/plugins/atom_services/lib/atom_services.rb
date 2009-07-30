# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
# === NOTE:
#  This plugin was originally based on the resource_feeder ruby on rails plugin
#  that can be found here: http://dev.rubyonrails.org/browser/plugins/resource_feeder

class Time
  def atom
    self.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
  end
end

module AtomServices
  extend self
    
  # failure will raise ArgumentError 
  def validate_gdata_params(params)
    time_params = ['updated_min', 'updated_max', 'published_min', 'published_max']
    int_params = ['start-index', 'max-results']
    text_params = ['q', 'author', 'alt']
    
    # gotta be an easier way to Set intersect an Array and Hash
    validate_gdata_time_params(time_params.collect{|k| params.has_key?(k) ? params[k] : nil}.compact)
    validate_gdata_int_params(int_params.collect{|k| params.has_key?(k) ? params[k] : nil}.compact)
    validate_gdata_text_params(text_params.collect{|k| params.has_key?(k) ? params[k] : nil}.compact)
  end
  
  def render_atom_feed_from(entries, meta) 
    render :text => atom_feed_from(entries, meta), :content_type => Mime::ATOM
  end
  
  def atom_feed_from(entries, meta)
    xml = Builder::XmlMarkup.new(:indent => 2)
      
    xml.instruct!
    xml.feed "xmlns" => "http://www.w3.org/2005/Atom", "xmlns:opensearch" => "http://a9.com/-/spec/opensearch/1.1/"  do
      xml.title(meta[:title])
      xml.id(meta[:url])
      xml.link(:rel => 'alternate', :type => 'text/html', :href => meta[:alt_url])
      xml.link(:rel => 'self', :type => 'application/atom+xml', :href => meta[:url])
      xml.subtitle(meta[:subtitle])
      
      #namespaces for result parameters
      xml.opensearch :totalResults do
        xml.text! meta[:total_results]
      end
      
      xml.opensearch :startIndex do
        xml.text! meta[:start_index] 
      end
      
      xml.opensearch :itemsPerPage do
        xml.text! meta[:items_per_page]
      end
      
      xml.updated meta[:updated_at].atom
      
      for entry in entries
        xml << entry.to_atom_entry
      end
    end
  end
  
  def render_atom_feed_for(resources, options = {}) 
    render :text => atom_feed_for(resources, options), :content_type => Mime::ATOM
  end
  
  def atom_feed_for(resources, options = {})
    xml = Builder::XmlMarkup.new(:indent => 2)
      
    xml.instruct!
    xml.feed "xmlns" => "http://www.w3.org/2005/Atom", "xmlns:opensearch" => "http://a9.com/-/spec/opensearch/1.1/"  do
      xml.title(options[:feed][:title])
      xml.id(options[:feed][:url])
      xml.link(:rel => 'alternate', :type => 'text/html', :href => options[:feed][:alt_url])
      xml.link(:rel => 'self', :type => 'application/atom+xml', :href => options[:feed][:url])
      xml.subtitle(options[:feed][:subtitle])
      
      #namespaces for result parameters
      xml.opensearch :totalResults do
        xml.text! options[:feed][:total_results]
      end
      
      xml.opensearch :startIndex do
        xml.text! options[:feed][:start_index] 
      end
      
      xml.opensearch :itemsPerPage do
        xml.text! options[:feed][:items_per_page]
      end
      
      if !resources.empty?
        xml.updated (resources.max{|a,b| a[:updated] <=> b[:updated]}[:updated].atom)
      else
        xml.updated Time.new.atom
      end
      
      for resource in resources
        xml.entry do
          xml.title(resource[:title], :type => 'html')
          xml.author do
            xml.name(resource[:author])
          end
          xml.content(resource[:content], :type => 'html')
          
          if resource[:tags] and resource[:tags].strip != ''
            resource[:tags].split(',').each do |tag|
              xml.category "term" => tag.downcase  
            end
          end
          
          xml.id(resource[:item_url])
          xml.link(:rel => 'alternate', :type => 'text/html', :href => resource[:item_url])
          xml.updated resource[:updated].atom
        end
      end
    end
  end

  private
  
  # this is very forgiving, but it makes cmd line testing with curl so much easier
  def validate_gdata_time_params(time_params)
    return unless time_params
    time_params.each do |v|
      time_val = Time.parse(v)
    end
  end
  
  def validate_gdata_int_params(int_params)
    return unless int_params
    int_params.each do |v|
      x = Integer(v)
    end
  end
  
  def validate_gdata_text_params(text_params)
    return unless text_params
    text_params.each do |v|
      if not v.empty? and v.type != 'String'
        raise ArgumentError
      end
    end
  end
      
end