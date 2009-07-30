# === COPYRIGHT:
#  Copyright (c) 2005-2008 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

#include ParamExtensions

module People::NumbersHelper
  
  def nilhash_number_with_delimiter(hash,key) 
    if(hash.blank?)
      return 0
    else
      return number_with_delimiter(hash[key])
    end
  end
    
  
  def aa_name(aaid)
    if(aaid.nil? or aaid == 0)
      return 'all'
    elsif(aa = ActivityApplication.find(aaid))
      return aa.shortname
    else
      return 'unknown'
    end
  end
  
  def link_to_object_numbers_action(linkobject)
    urlparams = {:action => :summary, linkobject.class.name.downcase.to_sym => linkobject.id}
    return link_to(linkobject.name, url_for(urlparams))
  end
    
  def url_for_itemlist(itemlist,options,params={})
    filteredparameters = FilterParams.new(options)
    filter_params = filteredparameters.option_values_hash
    options = {:controller => '/people/numbers', :action => itemlist}
    options.merge!(filter_params)
    options.merge!(params)
    return url_for(options)
  end
    
  def link_to_item(item,itemtype,filtered)
     return link_by_count(item.usercount,item.name, url_for(:action => itemtype, :id => item.id))
  end
  
  def link_to_userlist(text,options={},htmloptions={})
    filteredparameters = FilterParams.new(options)
    community = options[:community] || nil
    bycount = (options[:bycount].nil? ? false : options[:bycount])
    if(community)
      urlparams = {:controller => '/people/communities', :action => :userlist, :id => community.id, :connectiontype => 'joined'}
      options.delete(:communitytype)
    else
      urlparams = {:controller => '/people/colleagues', :action => :list}
    end
    urlparams.merge!(filteredparameters.option_values_hash)
    # must be logged in!
    if(@currentuser.nil?)
      return "#{text}"
    else
      if(bycount)
        return link_by_count(text,"#{text}",url_for(urlparams),htmloptions)
      else
        return link_to("#{text}",url_for(urlparams),htmloptions)
      end
    end
  end
  
  def link_number_to_userlist(number,options={},htmloptions={})
    link_to_userlist(number,options.merge({:bycount => true}),htmloptions={})
  end
  
  # this is honestly a bit absurd
  def almost_breadcrumbs(path,filterobject)
    breadcrumbs = link_to("Numbers",:controller => '/people/numbers', :action => :index )
    if(filterobject.nil?)
      breadcrumbs += " >> "
      breadcrumbs += "#{path.capitalize}"
    else
      objectklass = filterobject.class.name
      objectid = filterobject.id
      breadcrumbs += " >> "
      breadcrumbs += link_to("#{objectklass.pluralize}",:controller => '/people/numbers', :action => objectklass.downcase.pluralize )
      if(objectklass.downcase.pluralize != path)
        breadcrumbs += " >> "
        breadcrumbs += link_to("#{filterobject.name}",:controller => '/people/numbers', :action => objectklass.downcase, :id => objectid )
        breadcrumbs += " >> "
        breadcrumbs += "#{path.capitalize}"
      else
        breadcrumbs += " >> "
        breadcrumbs += "#{filterobject.name}"
      end
    end
    
    return breadcrumbs  
    
  end
  
end