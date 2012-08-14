# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE


class Category < ActiveRecord::Base
  acts_as_tree :order => 'name'
  has_and_belongs_to_many :submitted_questions
  
  has_many :expertise_areas, :dependent => :destroy
  has_many :users, :through => :expertise_areas
  has_many :expertise_events,:foreign_key => :expertise_id, :dependent => :destroy
  
  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false, :scope => :parent_id, :if => Proc.new { |cat| !cat.parent }
  
  UNASSIGNED = "uncategorized"
  ALL = "all"
  
  named_scope :filtered, lambda {|options| Category.category_conditions(options)}
  named_scope :root_categories, {:conditions => 'parent_id is null'}
  named_scope :show_to_public, {:conditions => 'show_to_public = 1'}
    
  
  def subcat_names
    self.children.collect{|c| c.name}.join(',')
  end
  
  # get intersection of users for aae routing
  def get_user_intersection(users_to_intersect)
    if users_to_intersect and users_to_intersect.length > 0
      User.narrow_by_routers(self.users.find(:all, :conditions => "accounts.id IN (#{users_to_intersect.collect{|u| u.id}.join(',')})"), Role::AUTO_ROUTE)
    else
      return []
    end
  end
  
  def get_experts(*args)
    users.find(:all, *args)
  end
  
  def is_top_level?
    return self.parent_id.nil?  
  end
  
  def self.find_root(*args)
    with_scope(:find => { :conditions => "parent_id is null" }) do
      find(*args)
    end
  end
   
  def full_name
    if parent
      return parent.name + ":" + name
    else
      return name
    end
  end
   
  def self.count_users_for_rootcats
      return self.count(:all, :joins => " join expertise_areas as ea on categories.id=ea.category_id",
     :conditions => 'parent_id is null', :group => "categories.name", :order => 'name')
  end 
  
  def self.count_users_for_rootcats_in_county(county, state)
    locid = Location.find_by_name(state).id
    return self.count(:all, :joins => " join expertise_areas as ea on categories.id=ea.category_id join expertise_counties_users as ctu on ctu.user_id=ea.user_id" + 
     " join counties on counties.id=ctu.county_id", :conditions => ["parent_id is null and counties.name=? and location_id=?", county, locid], :group => "categories.name", :order => "categories.name")
  end 
  
  def self.count_users_for_rootcats_in_state(statename) 
    locid = Location.find_by_name(statename).id
    return self.count(:all, :select => "distinct ctu.user_id", :joins => " join expertise_areas as ea on categories.id=ea.category_id join expertise_counties_users as ctu on ctu.user_id=ea.user_id" + 
    " join counties on counties.id=ctu.county_id", :conditions => ["parent_id is null and location_id=? and categories.id is not null", locid], :group => "categories.name", :order => "categories.name")
  end
  
  def Category.category_conditions(options=nil)
     if(options.nil?)
        options = {}
      end
      
      joins = []
      conditions = []

      # conditions << build_date_condition(options)
    #  conditions << build_entrytype_condition(options)
       if options[:location]
          joins <<  " join expertise_areas as ea on categories.id=ea.category_id join expertise_counties_users as ctu on ctu.user_id=ea.user_id" +
                        " join counties on counties.id=ctu.expertise_county_id"
          conditions << "parent_id is null"
          conditions << "location_id = #{options[:location].id}"
          if options[:county]
            conditions << "ctu.expertise_county_id = #{options[:county].id}"
          end
       end
       
       return {:joins => joins.compact, :conditions => conditions.compact.join(' AND ')}
  end
  
  def self.catuserfilter_count(options={},returnarray = false)
    countarray = self.filtered(options).count( 'ctu.user_id', :group => "#{table_name}.name", :distinct => true)
    if(returnarray)
      return countarray
    else
      returnhash = {}
      countarray.map{|values| returnhash[values[0]] = values[1].to_i}
      return returnhash
    end
  end
  
  # used for parameter searching
  def self.find_by_name_or_id(value)
    if(value.to_i != 0)
      # assume id value
      return self.find_by_id(value)
    elsif(value == Category::UNASSIGNED)
      return Category::UNASSIGNED
    else
      return self.find_by_name(value)
    end
  end
  
  # Callback to normalize the tagname before saving it. 
  def before_save
    self.name = self.class.normalizename(self.name)
  end
    
  class << self
  
    # normalize category names - intentionally does not allow "colons" (while tags and content buckets do)
    # convert whitespace to single space, underscores to space, Yank everything that's not alphanumeric except hyphen or whitespace (which is now single spaces)   
    def normalizename(name)
      # make an initial downcased copy - don't want to modify name as a side effect
      returnstring = name.downcase
      # now, use the replacement versions of gsub and strip on returnstring
      returnstring.gsub!('_',' ')
      returnstring.gsub!(/[^\w\s-]/,'')
      returnstring.gsub!(/\s+/,' ')
      returnstring.strip!
      returnstring
    end  
  end
  




    

  
end