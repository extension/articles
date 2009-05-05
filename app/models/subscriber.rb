# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Subscriber

  def self.retrieve_each(&block)
    check_time = Time.now.utc
    latest.each(&block)
    set_last_updated_time(check_time)
  end
  
  def self.retrieve_each_to(to,timeout, &block)
    old_time = AppConfig.configtable['fullrefresh_time']
    AppConfig.configtable['fullrefresh_time'] = to
    check_time = Time.now.utc
    latest(timeout).each(&block)
    set_last_updated_time(check_time)
    AppConfig.configtable['fullrefresh_time'] = old_time
  end
  
  private
  
  def self.latest(timeout = 2000)
    url = URI.parse(full_url)
    
    http = Net::HTTP.new(url.host, url.port)
    http.read_timeout = timeout
    response = http.get(url.path)
    objects_from(response)
  end

  def self.full_url
    "#{base_url_with_objects}#{url_for_time(last_updated_time)}"
  end

  def self.url_for_time(time)
    "/#{time.year}/#{time.month}/#{time.day}/#{time.hour}/#{time.min}/#{time.sec}"
  end

  def self.last_updated_time
    result = UpdateTime.find_by_site(class_to_create.name)
    if(result)
      result.last_update_time
    else
      basetime = Time.parse(AppConfig.configtable['fullrefresh_time'])
      basetime.utc
    end
  end

  def self.set_last_updated_time(time)
    update_time = UpdateTime.find_by_site(class_to_create.name) || UpdateTime.new(:site => class_to_create.name)
    update_time.update_attribute(:last_update_time, time)
  end

  def self.objects_from(response)
    return [] unless response.class == Net::HTTPOK    

    response_hash = Hash.from_xml(response.body)
    return [] unless response_hash[item_name_in_response_hash.pluralize]
    object_hashes_from(response_hash).collect { | each | 
      class_to_create.from_hash(each) 
    }
  end

  def self.object_hashes_from(response_hash)
    result = response_hash[item_name_in_response_hash.pluralize][item_name_in_response_hash]
    only_one_object_in(result) ? [result] : result
  end

  def self.only_one_object_in(hashes)
    hashes.class != Array
  end

  def self.item_name_in_response_hash
    class_to_create.name.underscore
  end

  def self.fetch_atom_feed(loadfromfile=nil)
    if(loadfromfile.nil?)
      url = URI.parse(full_url)
      http = Net::HTTP.new(url.host, url.port) 
      http.read_timeout = 300
      if url.query.nil?
        response = http.get(url.path)
      else
        response = http.get(url.path + "?" + url.query)
      end
      xmlcontent = response.body
    else
      if File.exists?(loadfromfile)
        xmlcontent = ''
        File.open(loadfromfile) { |f|  xmlcontent = f.read }
      end 
    end
    AtomEntry.entries_from_xml(xmlcontent)
  end
end
