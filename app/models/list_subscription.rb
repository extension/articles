# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class ListSubscription < ActiveRecord::Base
  belongs_to :list
  belongs_to :user

  named_scope :subscribers,  :include => [:user],  :conditions => "list_subscriptions.ineligible = 0 and list_subscriptions.optout = 0 and list_subscriptions.user_id > 0", :order => "users.last_name"
  named_scope :optout, :include => [:user], :conditions => "list_subscriptions.ineligible = 0 and list_subscriptions.optout = 1 and list_subscriptions.user_id > 0", :order => "users.last_name"  
  named_scope :ineligible, :include => [:user], :conditions => "(list_subscriptions.ineligible = 1 or list_subscriptions.emailconfirmed = 0) and list_subscriptions.user_id > 0", :order => "users.last_name"  
  named_scope :noidsubscribers, :conditions => "list_subscriptions.ineligible = 0 and list_subscriptions.optout = 0 and list_subscriptions.user_id = 0", :order => "list_subscriptions.email"
  
  named_scope :filteredsubscribers, lambda {|userlist,include|
    if(include)
      {:include => [:user], :conditions => "list_subscriptions.ineligible = 0 and list_subscriptions.optout = 0 and list_subscriptions.user_id IN (#{userlist.map{|user| "'#{user.id}'"}.join(',')})"}
    else
      {:include => [:user], :conditions => "list_subscriptions.ineligible = 0 and list_subscriptions.optout = 0 and list_subscriptions.user_id > 0 and list_subscriptions.user_id NOT IN (#{userlist.map{|user| "'#{user.id}'"}.join(',')})"}
    end
  }
  def notassociated?
    return self.user.nil?
  end

  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  class << self
    
    def people_subscriptions(list_ids,options = {})
      scope = scope(:find)
      sql  = "SELECT #{table_name}.*"
      sql << " FROM #{table_name}, #{User.table_name}"

      add_joins!(sql, options, scope)

      sql << " WHERE #{table_name}.`email` = #{User.table_name}.`email`"
      ids_list_condition = list_ids.map { |id| "'#{id}'"}.join(',')
      sql << "AND (#{table_name}.`list_id` IN (#{sanitize_sql(ids_list_condition)})) "
      sql << "AND #{sanitize_sql(options[:conditions])} " if options[:conditions]
      add_order!(sql, options[:order], scope)
      add_limit!(sql, options, scope)
      add_lock!(sql, options, scope)

      find_by_sql(sql)    
    end
    
    
    
    def associate_people(list_ids)
      sql = "UPDATE #{table_name},#{User.table_name}"
      sql << " SET #{table_name}.`user_id` = #{User.table_name}.`id`,"
      sql << " #{table_name}.`emailconfirmed` = #{User.table_name}.`emailconfirmed`,"
      sql << " #{table_name}.`ineligible` = (#{User.table_name}.retired = 1 OR #{User.table_name}.vouched = 0)"
      sql << " WHERE #{table_name}.`email` = #{User.table_name}.`email`"
      ids_list_condition = list_ids.map { |id| "'#{id}'"}.join(',')
      sql << " AND (#{table_name}.`list_id` IN (#{sanitize_sql(ids_list_condition)})) "
      return self.connection().update(sql)
    end
    
    def drop_subscriptions(deleteitems)
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
