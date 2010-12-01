# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class ExpertiseCounty < ActiveRecord::Base
  
  has_and_belongs_to_many :users
  belongs_to :expertise_location
  
  named_scope :filtered, lambda {|options| ExpertiseCounty.county_conditions(options)}
  
  # TODO: review heureka county reporting methods.  Justcode Issue #554
  
  def self.get_users_for_cats_in_county( countyid)
     cats_users = []
     if countyid
       cats_users=find_by_sql(["Select distinct accounts.id, accounts.first_name, accounts.last_name, accounts.login, roles.name, roles.id as rid from expertise_counties join expertise_counties_users as ctu on expertise_counties.id=ctu.expertise_county_id" + 
         " join expertise_areas as ea on ea.user_id=ctu.user_id join users on ctu.user_id=accounts.id left join user_roles on user_roles.user_id=accounts.id " +
         " left join roles on user_roles.role_id=roles.id where expertise_counties.id=? order by accounts.last_name", countyid])
     end
    cats_users
   end
 
   def self.get_users_for_counties(countyid, statename, cat)
     countys_users = Array.new
     locid = ExpertiseLocation.find_by_name(statename).id
     catid = Category.find_by_name(cat).id

     if (countyid)
     countys_users=find_by_sql(["Select distinct accounts.id, accounts.first_name, accounts.last_name, accounts.login, roles.name, roles.id as rid from expertise_counties join expertise_counties_users as ctu on ctu.expertise_county_id=expertise_counties.id join users on accounts.id=ctu.user_id" +
        " join expertise_areas as ea on ea.user_id=ctu.user_id left join user_roles on ctu.user_id=user_roles.user_id left join roles on user_roles.role_id=roles.id " + 
         " where ea.category_id=? and expertise_counties.expertise_location_id=? and expertise_counties.id=? order by accounts.last_name", catid, locid, countyid])
     else
      countys_users=find_by_sql(["Select distinct accounts.id, accounts.first_name, accounts.last_name, accounts.login, roles.name, roles.id as rid from expertise_counties join expertise_counties_users as ctu on ctu.expertise_county_id=expertise_counties.id join users on accounts.id=ctu.user_id" +
         " join expertise_areas as ea on ea.user_id=ctu.user_id left join user_roles on ctu.user_id=user_roles.user_id left join roles on user_roles.role_id=roles.id " +
         " where ea.category_id=? and expertise_counties.expertise_location_id=? order by accounts.last_name", catid, locid])
     end

     countys_users
   end

   def self.count_answerers_for_county_and_category(catname, statename)
    catid = Category.find_by_name(catname).id
    stateid = ExpertiseLocation.find_by_name(statename).id
    return self.count(:all, :joins => " join expertise_counties_users as ctu on expertise_counties.id=ctu.expertise_county_id join expertise_areas as ea on ctu.user_id=ea.user_id",
        :conditions => ['category_id= ? and expertise_counties.expertise_location_id=? ', catid, stateid], :group => "expertise_counties.name", :order => 'name')
    end
   
 
  
  def self.county_conditions(options=nil)
     if(options.nil?)
        options = {}
      end

      joins = []
      conditions = []

      # conditions << build_date_condition(options)
    #  conditions << build_entrytype_condition(options)
       if options[:location]
          joins << "join expertise_counties_users as ecu on ecu.expertise_county_id=expertise_counties.id join accounts on ecu.user_id=accounts.id join expertise_areas as ea on ecu.user_id=ea.user_id " + 
                    " join categories as c on ea.category_id=c.id "
          conditions << "parent_id is null"
          conditions << "expertise_counties.expertise_location_id = #{options[:location].id}"
       end
      
       return {:joins => joins.compact, :conditions => conditions.compact.join(' AND ')}
  end
  
  def self.expert_county_userfilter_count(options={},returnarray = false)
    countarray = self.filtered(options).count(:select => 'ecu.user_id', :group => "#{table_name}.name", :distinct => "true")
    if(returnarray)
      return countarray
    else
      returnhash = {}
      countarray.map{|values| returnhash[values[0]] = values[1].to_i}
      return returnhash
    end
  end
end