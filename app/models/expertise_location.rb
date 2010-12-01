# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class ExpertiseLocation < ActiveRecord::Base
  
  has_and_belongs_to_many :users
  has_many :expertise_counties
  
  named_scope :filtered, lambda {|options| ExpertiseLocation.loc_conditions(options)}
  
  def self.get_users_in_state(locid)
     find_by_sql(["Select distinct accounts.id, accounts.first_name, accounts.last_name, accounts.login, roles.name, roles.id as rid from expertise_locations join expertise_locations_users as lu on lu.expertise_location_id=expertise_locations.id " +
        "  join users on lu.user_id=accounts.id left join user_roles on accounts.id=user_roles.user_id left join roles on user_roles.role_id=roles.id " +
        " where expertise_locations.id=? order by accounts.last_name", locid])
   end
   
   def self.count_answerers_for_states_in_category(catname)
     catid = Category.find_by_name(catname).id
     return self.count(:all, :joins => " join expertise_locations_users as lu on expertise_locations.id=lu.expertise_location_id join expertise_areas as ea on lu.user_id=ea.user_id",
         :conditions => ['category_id= ?', catid], :group => "expertise_locations.name", :order => 'entrytype, name')
   end
   
   def self.loc_conditions(options=nil)
       if(options.nil?)
          options = {}
        end

        joins = []
        conditions = []

        # conditions << build_date_condition(options)
      #  conditions << build_entrytype_condition(options)
         if options[:category]
            joins << " join expertise_locations_users as lu on expertise_locations.id=lu.expertise_location_id join expertise_areas as ea on lu.user_id=ea.user_id " 
            conditions << "category_id= #{Category.find_by_name(options[:category]).id} "
         end

         return {:joins => joins.compact, :conditions => conditions.compact.join(' AND ')}
    end

    def self.expert_loc_userfilter_count(options={},returnarray = false)
      countarray = self.filtered(options).count( :group => "#{table_name}.name", :order => "entrytype, name")
      if(returnarray)
        return countarray
      else
        returnhash = {}
        countarray.map{|values| returnhash[values[0]] = values[1].to_i}
        return returnhash
      end
    end
  
end