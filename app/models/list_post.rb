# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
class ListPost < ActiveRecord::Base
  belongs_to :list
  belongs_to :user
  
  named_scope :bydate, lambda {|datecondition|
      conditions = "list_posts.status = 'success'"
      if(plusdate = ListPost.build_date_condition(datecondition))
        conditions += " AND #{plusdate}"
      end
      {:conditions => conditions, :order => 'list_posts.posted_at DESC'}
  }
    
  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  class << self
    
    def get_posting_stats(datecondition)
      messages = ListPost.bydate(datecondition).count
      senders = ListPost.bydate(datecondition).count(:all, :group => :senderemail).size
      listcount = ListPost.bydate(datecondition).count(:all, :group => :list_id).size
      totalsize = ListPost.bydate(datecondition).sum(:size)
      return {:messages => messages, :senders => senders, :listcount => listcount, :totalsize => totalsize}
    end
    
    def get_count_bysender(datecondition,getsize = true, limit = 10)
      messagearray = ListPost.bydate(datecondition).count(:all, :group => :user_id, :order => "count_all DESC", :limit => limit)
      if(getsize)
        sizearray =  ListPost.bydate(datecondition).sum(:size, :group => :user_id)
        sizehash = {}
        sizearray.map{|entry| sizehash[entry[0]] = entry[1]}
        returnarray = messagearray.map{|entry| [entry[0],entry[1],sizehash[entry[0]]]}
      else
        returnarray = messagearray
      end
      return returnarray
    end

    def get_count_bylist(datecondition,getsize = true)
      messagearray = ListPost.bydate(datecondition).count(:all, :group => :list_id, :order => "count_all DESC")
      if(getsize)
        sizearray =  ListPost.bydate(datecondition).sum(:size, :group => :list_id)
        sizehash = {}
        sizearray.map{|entry| sizehash[entry[0]] = entry[1]}
        returnarray = messagearray.map{|entry| [entry[0],entry[1],sizehash[entry[0]]]}
      else
        returnarray = messagearray
      end
      return returnarray
    end
    
    def build_date_condition(datecondition)
      # TODO: other date conditions "today, thisweek, etc."
      if(datecondition.nil?)
        return nil
      elsif(datecondition == 'today')
        return 'DATE(list_posts.posted_at) = CURDATE()'
      elsif(datecondition == 'lastweek')
        return 'list_posts.posted_at > date_sub(curdate(), INTERVAL 1 WEEK)'
      elsif(datecondition == 'lastmonth')
        return 'list_posts.posted_at > date_sub(curdate(), INTERVAL 1 MONTH)'
      else
        return nil
      end
    end
          
    # def create_activity_records(sincewhen=nil)
    #   sql = "REPLACE INTO user_activities (created_at,community_id,user_id,activitycode,activity_application_id,created_by,object_type,object_id)"
    #   sql << " SELECT #{table_name}.posted_at, #{Communitylistconnection.table_name}.community_id, #{table_name}.user_id,501,1,#{table_name}.user_id,'LISTPOST',#{table_name}.list_id"
    #   sql << " FROM #{table_name}, #{List.table_name}, #{Communitylistconnection.table_name}"
    #   sql << " WHERE #{table_name}.list_id = #{List.table_name}.id"
    #   sql << " AND #{List.table_name}.id = #{Communitylistconnection.table_name}.list_id"
    #   if(!sincewhen.nil?)
    #     compare_time_string = sincewhen.strftime("%Y-%m-%d %H:%M:%S")
    #     sql <<  " AND #{table_name}.posted_at >= '#{compare_time_string}'"
    #   end
    #   return self.connection().update(sql)
    # end
    
    def import_list_posts_from_file(sourcefile,sincewhen=nil)
      # get the records
      parsedrecords = self.get_records_from_file(sourcefile,sincewhen)
      if(parsedrecords.blank?)
        return false
      end
      
      # insert
      insertedrecords = self.insert_records(parsedrecords)
      
      # update
      associatedlists = self.associate_lists(sincewhen)
      associatedusers = self.associate_users(sincewhen)
      
      return true
    end
      
    def insert_records(parsedrecords)
      sql = "INSERT IGNORE INTO #{table_name}"
      sql << " (`posted_at`, `listname`, `senderemail`, `size`, `messageid`, `status`, `created_at`) VALUES\n"
      sql << self.make_insert_records(parsedrecords)
      return self.connection().update(sql)
    end
    
    def associate_lists(sincewhen=nil)
      sql = "UPDATE #{table_name},#{List.table_name}"
      sql << " SET #{table_name}.`list_id` = #{List.table_name}.`id`"
      sql << " WHERE #{table_name}.`listname` = #{List.table_name}.`name`"
      # todo sincewhen?
      return self.connection().update(sql)
    end
    
    def associate_users(sincewhen=nil)
      primary = self.associate_users_primaryemail(sincewhen)
      additional = self.associate_users_additionalemails(sincewhen)
      return {:primary => primary, :additional => additional }
    end
    
    def associate_users_primaryemail(sincewhen=nil)
      sql = "UPDATE #{table_name},#{User.table_name}"
      sql << " SET #{table_name}.`user_id` = #{User.table_name}.`id`"
      sql << " WHERE #{table_name}.`senderemail` = #{User.table_name}.`email`"
      # todo sincewhen?
      return self.connection().update(sql)
    end

    def associate_users_additionalemails(sincewhen=nil)
      # second from user_emails table
      sql = "UPDATE #{table_name},#{UserEmail.table_name}"
      sql << " SET #{table_name}.`user_id` = #{UserEmail.table_name}.`user_id`"
      sql << " WHERE #{table_name}.`senderemail` = #{UserEmail.table_name}.`email`"
      # todo sincewhen?
      return self.connection().update(sql)
    end
    
    def make_insert_records(parsedrecords)
      output = []
      now = Time.now.utc
      timeformat = '%Y-%m-%d %H:%M:%S'
      parsedrecords.each do |r|
        output << "('#{r[:posted_at].strftime(timeformat)}','#{r[:listname]}','#{r[:senderemail]}',#{r[:size].to_i},'#{r[:messageid]}','#{r[:status]}','#{now.strftime(timeformat)}')"
      end
      return output.join(",")
    end
    
    def get_records_from_file(sourcefile,sincetime=nil)
      returnrecords = []
      begin      
        File.open(sourcefile).each do |line|
          parsedrecord = self.parse_post_record(line.chomp,sincetime)
          if(!parsedrecord.blank?)
            returnrecords << parsedrecord
          end
        end
      rescue
        return []
      end
      
      return returnrecords
    end
        
    def parse_post_record(record,sincetime=nil)
      returnhash = {}
      parser = /([A-Za-z]{3} [\d]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} [0-9]{4}) \(([\d]+)\) post to ([A-Za-z\-_]*) from (([^@\s]+)@((?:[-a-zA-Z0-9]+\.)+[a-zA-Z]{2,}))\, size=([\d]*)\, message-id=<([a-zA-Z0-9%@.\-]*)>\, ([a-z]*)/
      if (record =~ parser)
        record_date =  Time.parse($1).utc
        if(sincetime.nil? or (!sincetime.nil? and record_date >= sincetime))
          returnhash[:posted_at] = record_date
          returnhash[:listname] = $3
          returnhash[:senderemail] = $4
          returnhash[:size] = $7
          returnhash[:messageid] = $8
          returnhash[:status] = $9
        end
      end
      return returnhash
    end
  end
  
  
end
