# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class MailmanList
  
  # class variables
  @@mailmanpath = '/services/mailman/bin'
  @@python = '/usr/bin/python'
  @@defaultowner = "extensionlistsmanager@extension.org"
  #cattr_accessor :mailmanpath,:python, :defaultowner  # NOTE!!! depends on active record!
  attr_accessor :name, :password, :members, :invalidmembers, :exists, :config, :owners
  

  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  class << self
    
    #get the names of the lists that are currently in mailman
    def get_mailman_list_names()
      process = "#{@@mailmanpath}/list_lists -b"
      output = %x{#{process}}
      return output
    end
  
  end
  
  
  def initialize(name,getmembers=true,testmode=false)
    @name = name
    @newlist = false
    @members = Array.new
    @owners = Array.new
    @invalidmembers = Array.new
    @config = Hash.new
    @update_mailman = false
    @testmode = testmode
    if(getmembers)
      @exists = self.get_members(true)
      self.get_owners(true) unless !@exists
    end
    if !@exists
      newlist()
    else
      get_config()
    end
  end
  
  def update_mailman?()
    if @update_mailman
      return true
    else
      return false
    end
  end
  
  def update_list()
    update_string = ""
    @config.each{|k,v| update_string << "#{k}=#{v}\n"}
    if @testmode
      puts "  list configuration being sent to mailman:\n#{update_string}"
    else
      puts "  sending list configuration to mailman"
      File.open("listconfig.txt", 'w') {|f| f.write(update_string) }
      process = "#{@@mailmanpath}/config_list --inputfile=listconfig.txt #{@name}"
      proc = IO.popen(process, "w+")
      proc.close_write
      proc.close
      system("rm listconfig.txt")
    end
  end
  
  def remove_members(memberarray)
    if memberarray.size > 0
      process = "#{@@mailmanpath}/remove_members --file=- #{@name}"
      puts "  removing #{memberarray.size} member(s): #{memberarray.join(",")}"
      puts "  running command: #{process}"
      if !@testmode
        proc = IO.popen(process, "w+")
        proc.puts memberarray.join("\n")
        proc.close_write
        proc.close
      end  
    else
      puts "  no members removed"
    end
    return true
  end
  
  def remove_list()
    puts "removing list: #{@name}"
    process = "#{@@mailmanpath}/rmlist -a #{@name}"
    puts "running command: #{process}"
    if !@testmode
      output = %x{#{process}}
      return output
    end
  end
  
  def add_members(memberarray)
    if memberarray.size > 0
      # # this needs to use a temporary file to avoid broken pipe errors.
      # tmpfilename = "/tmp/" + self.name + ".addmembers.input" 
      # # write to the output file
      # f_addmembers = File.open(tmpfilename, "w+")
      # f_addmembers.puts memberarray.join("\n")
      # f_addmembers.close
      process = "#{@@mailmanpath}/add_members --regular-members-file=- #{@name}"
      puts "  adding #{memberarray.size} member(s): #{memberarray.join(",")}"
      puts "  running command: #{process}"
      if !@testmode
        proc = IO.popen(process, "w+")
        proc.puts memberarray.join("\n")
        proc.close_write
        proc.readlines # read the response back, but we don't care about it
        proc.close
      end
      # File.unlink(tmpfilename)
    else
      puts "  no members added"
    end
    return true
  end
  
  def get_members(forcerefresh=false)
    if(!@members.nil? and !forcerefresh)
      return true
    end
    process = "#{@@mailmanpath}/list_members #{@name} 2>&1"
    output = %x{#{process}}
    if output.empty? #list that has no members, but exists
      return true
    elsif output.match("No such list")
      return false
    else
      output.each { |address|
        # validate email - this regex might should be pulled out 
        # to a higher level since it's used elsewhere in the app
        if /^([^@\s]+)@((?:[-a-zA-Z0-9]+\.)+[a-zA-Z]{2,})$/.match(address)
          @members << address.strip.downcase
        else
          @invalidmembers << address.strip
        end 
      }
      return true
    end
  end
  
  def get_owners(forcerefresh=false)
    if(!@owners.nil? and !forcerefresh)
      return true
    end
    process = "#{@@mailmanpath}/list_owners #{@name}"
    output = %x{#{process}}
    if output.empty?
      return false
    else
      output.each { |address|
        @owners << address.strip.downcase
      }
      return true
    end
  end  
    
  def newlist()
    @newlist = true
    @password = random_password
    process = "#{@@mailmanpath}/newlist -l en #{@name} #{@@defaultowner} #{@password}"
    puts "Creating new list: #{@name}\n  running command: #{process}"
    set_real_name(@name)
    set_subject_prefix(@name)
    set_max_message_size_unlimited()
    set_archive_privacy(true)
    set_max_num_recipients(0)
    set_list_advertised(false)
    set_subscribe_policy(3)
    set_send_reminders(false)
    set_admin_notify_changes(false)
    set_send_welcome_msg(false)
    set_send_goodbye_msg(false) 
    set_footer_links()
    if !@testmode
      #result = %x{#{process}}
      proc = IO.popen(process, "w+")
      proc.close_write
      proc.close
      get_config()
      @update_mailman = true
    end
  end
  
  def get_config()
    process = "#{@@mailmanpath}/config_list --outputfile=- #{@name}"
    output = %x{#{process}}
    if output.empty?
      return false
    else
      output.each {|line|
        next if /^#/.match(line) or /"""/.match(line)
        k, v = line.split(/=/)
        if(!k.nil? and !v.nil?)
          @config[k.strip]=v.strip
        end
      }
      return true
    end
  end
  
  def set_admin_notify_changes(notify)
    updatestring = notify ? "true" : "false"
    puts "  setting admin notify to #{updatestring}"
    @config["admin_notify_mchanges"] = notify ? 1 : 0
    @update_mailman = true
  end
  
  def get_archive_privacy()
    if @config["archive_private"] == "True" or @config["archive_private"].to_s == "1"
      return true
    else
      return false
    end
  end
  
  #the maximum number of recipients for a discussion without requiring admin approval. set to 0 for no limit
  def set_max_num_recipients(numrecipients)
    puts "  changing the maximum number of recipients to #{numrecipients}"
    @config["max_num_recipients"] = numrecipients
    @update_mailman = true
    return true
  end
  
  def set_subject_prefix(prefix)
    puts "  setting subject prefix to #{prefix}"
    @config["subject_prefix"] = "'[#{prefix}]'"
    @update_mailman = true
    return true
  end
  
  def set_real_name(name)
    puts "  setting real name to #{name}"
    @config["real_name"] = "'#{name}'"
    @update_mailman = true
    return true
  end
  
  def set_archive_privacy(isprivate)
    updatestring =isprivate ? "private" : "public"
    puts "  changing list archives to #{updatestring}" 
    @config["archive_private"] = isprivate ? 1 : 0
    @update_mailman = true
    return true
  end
  
  def set_max_message_size_unlimited()
    puts "  setting max message size to unlimited"
    @config["max_message_size"] = 0
    @update_mailman = true
    return true
  end
  
  def get_list_privacy()
    if @config["advertised"] == "True" or @config["advertised"].to_s =="1"
      return true
    else
      return false
    end      
  end
  
  def set_send_reminders(bool)
    updatestring = bool ? "true" : "false" 
    puts "  changing send_reminders to #{updatestring}"
    @config["send_reminders"] = bool ? 1 : 0
    @update_mailman = true
  end
  
  def set_list_advertised(advertised)
    updatestring = advertised ? "Advertised" : "Hidden"
    puts "  changing list advertisement to #{updatestring}"
    @config["advertised"] = advertised ? 1 : 0
    @update_mailman = true
    return true
  end
  
  def add_owners(memberarray)
    if memberarray.size > 0 
      puts "  adding #{memberarray.size} owner(s) to #{@name} (#{memberarray.join(",")})"
      prepared_owners = Array.new
      memberarray.each{|email| @owners.push(email)}
      @owners.each{|email| prepared_owners.push("'#{email}'")}
      @config["owner"] = "[#{prepared_owners.join(",")}]"
      @update_mailman = true
    else
      puts "  no owners to add"
    end
    return true
  end
  
  def remove_owners(memberarray)
    if memberarray.size > 0
      puts "  removing #{memberarray.size} owner(s) from #{@name} (#{memberarray.join(",")})" 
      prepared_owners = Array.new
      @owners = @owners - memberarray
      @owners.each{|email| prepared_owners.push("'#{email}'")}
      @config["owner"] = "[#{prepared_owners.join(",")}]"
      @update_mailman = true
    else
      puts "  no owners to remove"
    end
    return true
  end
  
  def random_password(size = 5)
    c = %w(b c d f g h j k l m n p qu r s t v w x z ch cr fr nd ng nk nt ph pr rd sh sl sp st th tr)
    v = %w(a e i o u y)
    f, r = true, ''
    (size * 2).times do
      r << (f ? c[rand * c.size] : v[rand * v.size])
      f = !f
    end
    r
  end
  
  def newlist?()
    return @newlist
  end
  
  def get_password()
    if !@password.nil?
      return @password
    else
      return nil
    end
  end
  
  #1 - confirm email addresss
  #2 - require admin approval
  #3 - confirm and require approval
  def set_subscribe_policy(policy_number)
    puts "  setting subscription policy to require admin approval and email confirmation"
    @config["subscribe_policy"] = policy_number
    @update_mailman = true
  end
  
  def set_footer_links()
    puts "  setting list message footer to point to people.extension.org list controller"
    @config["msg_footer"] = "\"\"\"_______________________________________________\n%(real_name)s mailing list\n%(real_name)s@%(host_name)s\nhttps://people.extension.org/lists/%(real_name)s\n\n\"\"\""
    @config["digest_footer"] = "\"\"\"_______________________________________________\n%(real_name)s mailing list\n%(real_name)s@%(host_name)s\nhttps://people.extension.org/lists/%(real_name)s\n\n\"\"\""
    @update_mailman = true
  end
  
  def set_send_welcome_msg(bool)
    updatestring = bool ? "true" : "false" 
    puts "  changing send_welcome_msg to #{updatestring}"
    @config["send_welcome_msg"] = bool ? 1 : 0
    @update_mailman = true
  end
  
  def set_send_goodbye_msg(bool)
    updatestring = bool ? "true" : "false" 
    puts "  changing send_goodbye_msg to #{updatestring}"
    @config["send_goodbye_msg"] = bool ? 1 : 0
    @update_mailman = true
  end

end
