# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
include GroupingExtensions

class Institution < ActiveRecord::Base
  include Logo
  serialize :additionaldata
  INSTITUTION_INVALID = 0
  LANDGRANT = 1
  STATE = 2
  FEDERAL = 3
  USERCONTRIBUTED = 4
  
  # landgrantypes
  UNCATEGORIZED = 0
  MORRILL_1862 = 1
  MORRILL_1890 = 2
  TRIBAL = 3
  
  
  
  has_many :users
  belongs_to :location
  
  belongs_to :institutionalteam, :class_name => "Community"
  
  validates_presence_of :name
  
  before_create :normalizemyname
  before_update :normalizemyname

  named_scope :landgrant, :conditions => {:entrytype => Institution::LANDGRANT}
  named_scope :state, :conditions => {:entrytype => Institution::STATE}
  named_scope :federal, :conditions => {:entrytype => Institution::FEDERAL}
  named_scope :usercontributed, :conditions => {:entrytype => Institution::USERCONTRIBUTED}

  named_scope :filtered, lambda {|options| userfilter_conditions(options)}
  named_scope :displaylist, {:group => "#{table_name}.id",:order => "entrytype,name"}


  def normalizemyname
    self.normalizedname = self.class.normalizename(self.name)
  end
  
  def img
    existing_university_logo(code)
  end

    
  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  class << self    
    
    def get_federal_nolocation
      find(:all, :conditions => ["location_id = 0 AND entrytype = #{FEDERAL}"], :order => "entrytype,name")
    end
    
    def searchmatching(opts = {})
      searchterm = opts.delete(:searchterm).downcase+'%'
      conditions = ["LOWER(name) like ?",searchterm]
      finder_opts = {:conditions => conditions}      
      find(:all,opts.merge(finder_opts))
    end
        
    def normalizename(name)
      return name.downcase.gsub(/[^a-z0-9:_-]/,'')
    end
    
    def find_existing_or_create_new_user_institution(name,creatorlogin)
      norname = self.normalizename(name)
      i = find_by_normalizedname(norname)
      if(i.nil?)
        i = create(:name => name, :creatorlogin => creatorlogin, :entrytype => USERCONTRIBUTED)
      end
      return i
    end
    
    def label_to_entrytypes(label)
      case label
      when 'system'
        [Institution::LANDGRANT, Institution::STATE,Institution::FEDERAL]
      when 'landgrant'
        [Institution::LANDGRANT]
      when 'state'
        [Institution::STATE]
      when 'federal'
        [Institution::FEDERAL]
      when 'usercontributed'
        [Institution::USERCONTRIBUTED]
      when 'all'
        [Institution::LANDGRANT, Institution::STATE,Institution::FEDERAL,Institution::USERCONTRIBUTED]
      else
        return nil
      end
    end
    
    def import_domains(file)
      values = CSV::Reader.parse(File.new(file, 'r')).collect {|row| row}.compact
      values.each do |name,domain|
        i = Institution.find_by_name(name)
        if(!i.nil?)
          i.update_attribute(:domain, domain)
        end
      end
    end
    
    def find_by_referer(referer)
      return nil unless referer
      begin
        uri = URI.parse(referer)
      rescue URI::InvalidURIError => e
        nil
      end
      return nil unless uri.kind_of? URI::HTTP
      return nil unless uri.host
      return nil if uri.host.empty?
      domain = uri.host.split('.').slice(-2, 2).join(".") rescue nil
      # handle some exceptions
      if(domain == 'bia.edu')
        domain = uri.host.split('.').slice(-3, 3).join(".") rescue nil
      elsif(domain == 'nd.us')
        domain = uri.host.split('.').slice(-4, 4).join(".") rescue nil
      elsif(domain == 'mt.us')
        domain = uri.host.split('.').slice(-4, 4).join(".") rescue nil
      elsif(domain == 'nm.us')
        domain = uri.host.split('.').slice(-4, 4).join(".") rescue nil
      elsif(domain == 'clu.edu')
        domain = uri.host.split('.').slice(-3, 3).join(".") rescue nil
      end
      return find_by_domain(domain) if domain
    end    

  end
  
end


