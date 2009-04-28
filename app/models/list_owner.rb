# === COPYRIGHT:
#  Copyright (c) 2005-2008 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class ListOwner < ActiveRecord::Base
  belongs_to :list
  belongs_to :user
  

  named_scope :idowners,  :joins => [:user],  :conditions => "list_owners.user_id > 0", :order => "users.last_name"  
  named_scope :moderators,  :joins => [:user],  :conditions => "list_owners.ineligible = 0 and list_owners.moderator = 1 and list_owners.user_id > 0", :order => "users.last_name"
  named_scope :nonmoderators, :joins => [:user], :conditions => "list_owners.ineligible = 0 and list_owners.moderator = 0 and list_owners.user_id > 0", :order => "users.last_name"  
  named_scope :noidowners, :conditions => "list_owners.user_id = 0 and list_owners.email != '#{AppConfig.configtable['default-list-owner']}'", :order => "list_owners.email"
  
  def notassociated?
    return self.user.nil?
  end

  def ineligible_for_mailman?
    return (self.nomailman? or !self.emailconfirmed?)
  end
  
  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  class << self
    
    def associate_people(list_ids)
      sql = "UPDATE #{table_name},#{User.table_name}"
      sql << " SET #{table_name}.`user_id` = #{User.table_name}.`id`,"
      sql << " #{table_name}.`emailconfirmed` = #{User.table_name}.`emailconfirmed`,"
      sql << " #{table_name}.`ineligible` = (#{User.table_name}.retired = 1 OR #{User.table_name}.vouched = 0)"
      sql << " WHERE #{table_name}.`email` = #{User.table_name}.`email`"
      ids_list_condition = list_ids.map { |id| "'#{id}'"}.join(',')
      sql << "AND (#{table_name}.`list_id` IN (#{sanitize_sql(ids_list_condition)})) "
      return self.connection().update(sql)
    end
    
    
    def drop_ownerships(deleteitems)
      if(deleteitems.is_a?(Array) and deleteitems[0].is_a?(List))
        ids_list_condition = deleteitems.map { |id| "'#{id}'"}.join(',')
        wherecondition = " WHERE (#{table_name}.`list_id` IN (#{sanitize_sql(ids_list_condition)}))"
      elsif(deleteitems.is_a?(Array) and deleteitems[0].is_a?(User))
        ids_list_condition = deleteitems.map { |id| "'#{id}'"}.join(',')
        wherecondition = " WHERE (#{table_name}.`user_id` IN (#{sanitize_sql(ids_list_condition)}))"
      elsif(deleteitems.is_a?(User))
        wherecondition = " WHERE #{table_name}.`user_id` = #{deleteitems.id}"
      elsif(deleteitems.is_a?(List))
        wherecondition = " WHERE (#{table_name}.`list_id` = #{deleteitems.id}"
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
