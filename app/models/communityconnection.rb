# === COPYRIGHT:
#  Copyright (c) 2005-2008 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Communityconnection < ActiveRecord::Base
  # must match namedscopes for the community
  TYPES = {'wantstojoin' => 'Wants to Join Community',
           'interest' => 'Has interest in Community',
           'nointerest' => 'Does not have in Community',
           'members' => 'Community Members',
           'leaders' => 'Community Leaders',
           'joined' => 'Joined Community',           
           'list' => 'List Members',
           'invited' => 'Invited to Membership',
           'interested' => 'Interest, Leaders, and Wants to Join',
           'users' => 'All Connections'}
    
  # codes
  INVITEDLEADER = 201
  INVITEDMEMBER = 202
  
  belongs_to :community
  belongs_to :user
  belongs_to :connector, :class_name => "User", :foreign_key => "connected_by"
  
  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  class << self
  
    def self.per_page
      50
    end
    
    def connection_condition(connectiontype)
      case connectiontype
      when 'leaders'
        returncondition = "communityconnections.connectiontype = 'leader'"
      when 'leader'
        returncondition = "communityconnections.connectiontype = 'leader'"           
      when 'members'
        returncondition = "communityconnections.connectiontype = 'member'"
      when 'member'
        returncondition = "communityconnections.connectiontype = 'member'"
      when 'joined'
        returncondition = "communityconnections.connectiontype IN ('leader','member')"
      when 'interest'
        returncondition = "communityconnections.connectiontype = 'interest'"
      when 'wantstojoin'
        returncondition = "communityconnections.connectiontype = 'wantstojoin'"
      when 'invited'
        returncondition = "communityconnections.connectiontype = 'invited'"
      when 'interested'
        returncondition = "communityconnections.connectiontype IN ('leader','wantstojoin','interest')"
      when 'nointerest'
        returncondition = "communityconnections.connectiontype = 'nointerest'"        
      else
        returncondition = "communityconnections.connectiontype IN ('leader','member','invited','wantstojoin','interest')"
      end
      
      return returncondition      
    end
  
    def drop_connections(deleteitems)
      if(deleteitems.is_a?(Array) and deleteitems[0].is_a?(Community))
        ids_list_condition = deleteitems.map { |id| "'#{id}'"}.join(',')
        wherecondition = " WHERE (#{table_name}.`community_id` IN (#{sanitize_sql(ids_list_condition)}))"
      elsif(deleteitems.is_a?(Array) and deleteitems[0].is_a?(User))
        ids_list_condition = deleteitems.map { |id| "'#{id}'"}.join(',')
        wherecondition = " WHERE (#{table_name}.`user_id` IN (#{sanitize_sql(ids_list_condition)}))"
      elsif(deleteitems.is_a?(User))
        wherecondition = " WHERE #{table_name}.`user_id` = #{deleteitems.id}"
      elsif(deleteitems.is_a?(List))
        wherecondition = " WHERE (#{table_name}.`community_id` = #{deleteitems.id}"
      else
        # nothing
        return 0
      end
        
      sql = "DELETE FROM #{table_name}"
      sql << wherecondition
      return self.connection().delete(sql)      
    end
    
  end
end