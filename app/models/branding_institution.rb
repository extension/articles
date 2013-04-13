# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at https://github.com/extension/darmok/wiki/LICENSE

class BrandingInstitution < ActiveRecord::Base
  belongs_to :location
  belongs_to :logo


  # TODO: this function is a little silly no?
  def self.find_by_referer(referer)
    return nil unless referer
    begin
      uri = URI.parse(referer)
    rescue URI::InvalidURIError => e
      nil
    end
    return nil unless uri.kind_of? URI::HTTP
    return nil unless uri.host
    return nil if uri.host.empty?
    referer_domain = uri.host.split('.').slice(-2, 2).join(".") rescue nil
    # handle some exceptions
    if(referer_domain)
      return find(:first, :conditions => ["referer_domain = '#{referer_domain}'"])
    else
      return nil
    end
  end  
end