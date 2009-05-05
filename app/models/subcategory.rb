class Subcategory
  
  def self.full_url
    AppConfig.configtable['subcategory_feed']
  end
  
  def self.import_subcats
    url = URI.parse(full_url)
    http = Net::HTTP.new(url.host, url.port)
    http.read_timeout = 3000
    response = http.get(url.path)
    raise "Feed was not successfully retrieved." unless response.class == Net::HTTPOK
    response_hash = Hash.from_xml(response.body)
    raise "Feed does not have the correct named elements." unless response_hash['categories']
    
    result = response_hash['categories']
    
    if result.class != Array
      result = [result]
    end
    
    create_subcats_from_hash(result)
  end
  
  def self.create_subcats_from_hash(array_of_hashes)
    
    array_of_hashes.each do |hash|
      if (super_tag = Tag.find_by_name(hash['name'].strip) ) #and (whitelist.include?(parent_category.name))
        super_tag.sub_tags.destroy_all

        if hash['subcat_names'] and hash['subcat_names'].strip != ''
          super_tag.sub_tags <<
            hash['subcat_names'].split(',').collect{|sc| Tag.find_by_name(sc.strip) || Tag.create(:name => sc.strip)}
        end
      end
    end
  end  
  
end
