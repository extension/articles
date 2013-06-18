# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class MailmanList < ActiveRecord::Base
  self.establish_connection :people


  
  # MAILMAN TYPES
  MAILMAN_TRUE = 1
  MAILMAN_FALSE = 0
  
  MAILMAN_UNLIMITED = 0
  
  MAILMAN_SUBSCRIBE_CONFIRM = 1   # subscribers must confirm email
  MAILMAN_SUBSCRIBE_MODERATE = 2  # admins must approve subscriptions
  MAILMAN_SUBSCRIBE_CONFIRM_AND_MODERATE = 3  # confirm and admin approval
  
  MAILMAN_ACCEPT = 0
  MAILMAN_HOLD = 1

  belongs_to :community
    
  validates_length_of :name, :maximum=>50
  
  named_scope :managed, {:conditions => ["name != 'mailman'"]}
  named_scope :needs_mailman_update, {:conditions => ["last_mailman_update IS NULL or updated_at > last_mailman_update"]}
  
  # mailman attributes
  @has_mailman_list = nil
  attr_accessor :mailman_configuration, :mailman_members, :mailman_owners, :mailman_invalid_members
  
  before_create :set_random_password
    
    
  def is_announce_list?
    return (self.name == AppConfig.configtable['list-announce'])
  end
  
  def subscriber_count
    if(self.is_announce_list?)
      User.where(:announcements => true).list_eligible.count
    else
      case connectiontype
      when 'leaders'
        self.community.leaders.list_eligible.count
      when 'joined'
        self.community.joined.list_eligible.count
      when 'interested'
        self.community.interested.list_eligible.count
      else
        0
      end
    end
  end


  def list_subscriptions
    case connectiontype
    when 'leaders'
      typelist = "'leader'"
    when 'joined'
      typelist = "'member','leader'"
    else
      return []
    end

    sql = <<-END_SQL.gsub(/\s+/, " ").strip
      SELECT `people`.`email` FROM `people` INNER JOIN `community_connections` ON `people`.`id` = `community_connections`.`person_id` 
      WHERE `community_connections`.`community_id` = #{self.community_id} 
      AND (retired = false and vouched = true) 
      AND (connectiontype IN (#{typelist}))
    END_SQL

    results = self.connection.execute(sql)
    addresses = []
    results.each do |r|
      addresses += r
    end 
    addresses
    
  end
        
  def self.per_page
    25
  end
      
  def self.find_by_name_or_id(searchterm)
    list = find_by_id(searchterm)
    if(list.nil?)
      list = find_by_name(searchterm)
    end
    return list
  end
  
  def self.find_or_createnewlist(listoptions)
    if(listoptions.nil? or listoptions[:name].nil?)
      return nil
    end
    
    makelistname = listoptions[:name].downcase
    list = List.find_by_name(makelistname)
    if(list.nil?)
      creationoptions = List.defaultoptions().merge(listoptions)
      # force the lowercase name
      creationoptions[:name] = makelistname
      list = List.create(creationoptions)
    end
    return list
  end
  
  def self.defaultoptions
    return {:advertised => false, :managed => true}
  end
  
  def self.find_announce_list
    List.find_by_name(AppConfig.configtable['list-announce'])
  end
  
  def set_random_password(size = 12)
    alphanumerics = [('0'..'9'),('A'..'Z'),('a'..'z')].map {|range| range.to_a}.flatten
    self.password = ((0...size).map { alphanumerics[Kernel.rand(alphanumerics.size)] }.join)
  end
    

  # -----------------------------------
  # MailMan methods
  # -----------------------------------
  def update_mailman?
    return (self.last_mailman_update.nil? or self.updated_at > self.last_mailman_update)
  end
  
  # calls mailman_members as a side effect
  def has_mailman_list?
    if(@has_mailman_list.nil?)
      if(members = self.mailman_members)
        @has_mailman_list = true
      else
        @has_mailman_list = false
      end
    end
    @has_mailman_list
  end
  
  def mailman_members(forcerefresh=false)
    if(!@mailman_members.nil? and !forcerefresh)
      return @mailman_members
    end
    @mailman_members = Array.new
    @mailman_invalid_members = Array.new
    process = "#{AppConfig.configtable['mailmanpath']}/list_members #{self.name} 2>&1"
    output = %x{#{process}}
    if output.empty? #list that has no members, but exists
      return []
    elsif output.match("No such list")
      return nil
    else
      output.each { |address|
        # validate email - this regex might should be pulled out 
        # to a higher level since it's used elsewhere in the app
        if EmailAddress.is_valid_address?(address)
          @mailman_members << address.strip.downcase
        else
          @mailman_invalid_members << address.strip
        end
      }
      return @mailman_members
    end
  end
  
  def mailman_owners(forcerefresh=false)
    if(!@mailman_owners.nil? and !forcerefresh)
      return @mailman_owners
    end
    @mailman_owners = Array.new
    process = "#{AppConfig.configtable['mailmanpath']}/list_owners #{self.name}"
    output = %x{#{process}}
    if output.empty?
      return []
    else
      output.each { |address|
        self.mailman_owners << address.strip.downcase
      }
      return @mailman_owners
    end
  end
  
  def mailman_configuration(forcerefresh=false)
    if(!@mailman_configuration.nil? and !forcerefresh)
      return @mailman_configuration
    end
    @mailman_configuration = Hash.new
    process = "#{AppConfig.configtable['mailmanpath']}/config_list --outputfile=- #{self.name}"
    output = %x{#{process}}
    if output.empty?
      return []
    else
      output.each {|line|
        next if /^#/.match(line) or /"""/.match(line)
        k, v = line.split('=')
        if(!k.nil? and !v.nil?)
          @mailman_configuration[k.strip]=v.strip
        end
      }
      return @mailman_configuration
    end
  end
  
  def mailman_configuration=(new_configuration_settings)
    if(@mailman_configuration.nil?)
      self.mailman_configuration # sets @mailman_configuration
    end
    @mailman_configuration.merge!(new_configuration_settings)    
    update_string = ""
    listconfig_file = "/tmp/mailman_listconfig_#{self.name}.txt"
    if(File.exists?(listconfig_file))
      system("rm #{listconfig_file}")
    end
    @mailman_configuration.each{|k,v| update_string << "#{k}=#{v}\n"}
    system("rm #{listconfig_file}") if File.exists?("#{listconfig_file}") #get rid of any possible remnants from previous runs
    File.open("#{listconfig_file}", 'w') {|f| f.write(update_string) }
    process = "#{AppConfig.configtable['mailmanpath']}/config_list --inputfile=#{listconfig_file} #{self.name}"
    proc = IO.popen(process, "w+")
    proc.close_write
    proc.close
    system("rm #{listconfig_file}")
    self.touch(:last_mailman_update)
    return @mailman_configuration
  end
  
  def update_mailman_members
    current_mailman_members = self.mailman_members
    subscriber_emails = self.list_subscriptions
    add_members = subscriber_emails - current_mailman_members
    remove_members = current_mailman_members - subscriber_emails
    self.add_mailman_members(add_members)
    self.remove_mailman_members(remove_members)
    # www won't have write access to people
    #self.touch(:last_mailman_update)
    return {:add_count => add_members.size, :remove_count => remove_members.size}
  end
  
  def default_mailman_configuration
    default_footerstring = "\"\"\"_______________________________________________\n%(real_name)s mailing list\n%(real_name)s@%(host_name)s\nhttps://www.extension.org/people/lists/%(real_name)s\n\n\"\"\""
    default_configuration = Hash.new
    default_configuration["real_name"] = "'#{self.name}'"
    default_configuration["subject_prefix"] = "'[#{self.name}]'"
    default_configuration["msg_footer"] = default_footerstring
    default_configuration["digest_footer"] = default_footerstring
    default_configuration["send_goodbye_msg"] = MAILMAN_FALSE
    default_configuration["send_welcome_msg"] = MAILMAN_FALSE
    default_configuration["subscribe_policy"] = MAILMAN_SUBSCRIBE_CONFIRM_AND_MODERATE
    default_configuration["advertised"] = MAILMAN_FALSE
    default_configuration["send_reminders"] = MAILMAN_FALSE
    default_configuration["max_message_size"] = MAILMAN_UNLIMITED
    default_configuration["archive_private"] = MAILMAN_TRUE
    default_configuration["max_num_recipients"] = MAILMAN_UNLIMITED
    default_configuration["admin_notify_mchanges"] = MAILMAN_FALSE
    if(!self.name.blank? and self.name == 'announce')
      default_configuration["generic_nonmember_action"] = MAILMAN_HOLD
    else
      default_configuration["generic_nonmember_action"] = MAILMAN_ACCEPT
    end
    owners = ["'#{AppConfig.configtable['default-list-owner']}'"]
    default_configuration["owner"] = "[#{owners.uniq.join(",")}]"
    return default_configuration
  end
  
  def create_or_update_mailman_list(forceupdate=false)
    if(!self.update_mailman? and !forceupdate)
      return true
    end
    if(!self.has_mailman_list?)
      process = "#{AppConfig.configtable['mailmanpath']}/newlist -l en #{self.name} #{AppConfig.configtable['default-list-owner']} #{self.password}"
      proc = IO.popen(process, "w+")
      proc.close_write
      proc.close
    end    
    # set default configuration
    self.mailman_configuration=self.default_mailman_configuration  
    # update members
    return self.update_mailman_members
  end
  
  protected
  
  def add_mailman_members(email_address_array)
    if email_address_array.size > 0
      # # this needs to use a temporary file to avoid broken pipe errors.
      # tmpfilename = "/tmp/" + self.name + ".addmembers.input" 
      # # write to the output file
      # f_addmembers = File.open(tmpfilename, "w+")
      # f_addmembers.puts email_address_array.join("\n")
      # f_addmembers.close
      process = "#{AppConfig.configtable['mailmanpath']}/add_members --regular-members-file=- #{self.name}"
      proc = IO.popen(process, "w+")
      proc.puts email_address_array.uniq.join("\n")
      proc.close_write
      proc.readlines # read the response back, but we don't care about it
      proc.close
      # File.unlink(tmpfilename)
    end
    return email_address_array.size
  end    
  
  def remove_mailman_members(email_address_array)
    if email_address_array.size > 0
      process = "#{AppConfig.configtable['mailmanpath']}/remove_members --file=- #{self.name}"
      proc = IO.popen(process, "w+")
      proc.puts email_address_array.uniq.join("\n")
      proc.close_write
      proc.close
    end
    return email_address_array.size
  end
  
end
