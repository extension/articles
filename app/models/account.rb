# === COPYRIGHT:
# Copyright (c) 2005-2009 North Carolina State University
# Developed with funding for the National eXtension Initiative.
# === LICENSE:
# BSD(-compatible)
# see LICENSE file or view at http://about.extension.org/wiki/LICENSE
require 'digest/sha1'
class Account < ActiveRecord::Base
  extend ConditionExtensions
  include TaggingScopes
  serialize :additionaldata
  ordered_by :default => "last_name,first_name ASC"  
  DEFAULT_TIMEZONE = 'America/New_York'
  attr_protected :is_admin
    
  
  before_save :set_encrypted_password
  before_validation :set_login_string
  
  
  validates_uniqueness_of :login, :on => :create
  validates_uniqueness_of :email
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-zA-Z0-9]+\.)+[a-zA-Z]{2,})$/
  validates_length_of :email, :maximum=>96
  validates_confirmation_of :password, :message => 'has to be the same in both fields. Please type both passwords again.'
  validates_length_of :password, :within => 6..40, :allow_blank => true
  validates_presence_of :email, :login
  
  has_many :submitted_questions, :foreign_key => 'submitter_id'
  
  named_scope :patternsearch, lambda {|searchterm|
    # remove any leading * to avoid borking mysql
    # remove any '\' characters because it's WAAAAY too close to the return key
    # strip '+' characters because it's causing a repitition search error
    sanitizedsearchterm = searchterm.gsub(/\\/,'').gsub(/^\*/,'$').gsub(/\+/,'').strip
    # in the format wordone wordtwo?
    words = sanitizedsearchterm.split(%r{\s*,\s*|\s+})
    if(words.length > 1)
      findvalues = { 
       :firstword => words[0],
       :secondword => words[1]
      }
      conditions = ["((first_name rlike :firstword AND last_name rlike :secondword) OR (first_name rlike :secondword AND last_name rlike :firstword))",findvalues]
    elsif(sanitizedsearchterm.to_i != 0)
      # special case of an id search - needed in admin/colleague searches
      conditions = ["id = #{sanitizedsearchterm.to_i}"]
    else
      findvalues = {
       :findlogin => sanitizedsearchterm,
       :findemail => sanitizedsearchterm,
       :findfirst => sanitizedsearchterm,
       :findlast => sanitizedsearchterm 
      }
      conditions = ["(email rlike :findemail OR login rlike :findlogin OR first_name rlike :findfirst OR last_name rlike :findlast)",findvalues]
    end
    {:conditions => conditions}
  }
  
  # override email write
  def email=(emailstring)
    write_attribute(:email, emailstring.mb_chars.downcase)
  end
    
  def first_name=(first_name_string)
    if(self.type == 'PublicUser' and first_name_string.blank?)
      write_attribute(:first_name, 'Anonymous')
    elsif(!first_name_string.blank?)
      write_attribute(:first_name, first_name_string.strip)
    end
  end
  
  def last_name=(last_name_string)
    if(self.type == 'PublicUser' and last_name_string.blank?)
      write_attribute(:last_name, 'Guest')
    elsif(!last_name_string.blank?)
      write_attribute(:last_name, last_name_string.strip)
    end
  end
    
  def fullname 
    return "#{self.first_name} #{self.last_name}"
  end
  
  # override timezone writer/reader
  # returns Eastern by default, use convert=false
  # when you need a timezone string that mysql can handle
  def time_zone(convert=true)
    tzinfo_time_zone_string = read_attribute(:time_zone)
    if(tzinfo_time_zone_string.blank?)
      tzinfo_time_zone_string = DEFAULT_TIMEZONE
    end
      
    if(convert)
      reverse_mappings = ActiveSupport::TimeZone::MAPPING.invert
      if(reverse_mappings[tzinfo_time_zone_string])
        reverse_mappings[tzinfo_time_zone_string]
      else
        nil
      end
    else
      tzinfo_time_zone_string
    end
  end
  
  def time_zone=(time_zone_string)
    mappings = ActiveSupport::TimeZone::MAPPING
    if(mappings[time_zone_string])
      write_attribute(:time_zone, mappings[time_zone_string])
    else
      write_attribute(:time_zone, nil)
    end
  end
  
  # since we return a default string from timezone, this routine
  # will allow us to check for a null/empty value so we can
  # prompt people to come set one.
  def has_time_zone?
    tzinfo_time_zone_string = read_attribute(:time_zone)
    return (!tzinfo_time_zone_string.blank?)
  end
      
  def expire_password
   # note, will not call before_update (good, not encrypting '') 
   # but it will call after_update to update the chat_account password
   self.update_attribute('password','')
  end
  
  def self.expire_passwords
   # TODO: en masse password update using SQL
  end
  
  # used for parameter searching
  def self.find_by_email_or_extensionid_or_id(value,valid_only = true)
    #TODO - there possibly may be an issue here with the conditional
   if(value.to_i != 0)
     # assume id value
     checkfield = 'id'
   elsif (value =~ /^([^@\s]+)@((?:[-a-zA-Z0-9]+\.)+[a-zA-Z]{2,})$/ )
     checkfield = 'email'
   elsif (value =~ /^[a-zA-Z]+[a-zA-Z0-9]+$/) 
     # looks like a valid extensionid 
     checkfield = 'login'
   else
     return nil
   end
   
   if(valid_only)
     return User.notsystem.validusers.send("find_by_#{checkfield}",value)
   else
     return Account.send("find_by_#{checkfield}",value)
   end
  end
  
  def self.systemuser
   find(1)
  end
  
  def self.systemuserid
   1
  end
  
  def self.anyuser
   0
  end
  
  def self.per_page
   20
  end
  
  def set_login_string(reset=false)
    if(reset or self.login.blank?)
      if(self.type == 'User')
        self.base_login_string = (self.first_name + self.last_name.each_char[0]).mb_chars.downcase.gsub!(/[^\w]/,'')
      elsif(self.type == 'PublicUser')
        self.base_login_string = 'public'
      end
    
      # get maximum increment
      if(max = self.class.maximum(:login_increment,:conditions => "base_login_string = '#{self.base_login_string}'"))
        self.login_increment = max + 1
      else
        self.login_increment = 1
      end
    
      # set login
      self.login = "#{self.base_login_string}#{self.login_increment.to_s}"
    end
    return true
  end
  
  protected
  def encrypt_password_string(clear_password_string)
   Digest::SHA1.hexdigest(clear_password_string)
  end
   
  def set_encrypted_password
   self.password = self.encrypt_password_string(self.password) if (!self.password.blank? && self.password_changed?)
  end
  

    
end