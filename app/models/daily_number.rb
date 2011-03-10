# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class DailyNumber < ActiveRecord::Base
  belongs_to :datasource, :polymorphic => true
  
  PUBLISHED_ITEM_TYPES = ['published articles','published faqs','published events','published news','published features','published learning lessons']
  
  
  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  
  def self.update_or_create(datasource,datatype,datadate,values)
    if(datasource.is_a?(Class))
      datasource_type = datasource.name
      findconditions = {:datasource_type => datasource_type,:datasource_id => 0, :datatype => datatype, :datadate => datadate}
      createoptions = {:datasource_type => datasource_type, :datasource_id => 0, :datatype => datatype, :datadate => datadate, :total => values[:total], :thatday => values[:thatday]}
    else
      datasource_type = datasource.class.name
      findconditions = {:datasource_type => datasource_type,:datasource_id => datasource.id, :datatype => datatype, :datadate => datadate}
      createoptions = {:datasource => datasource, :datatype => datatype, :datadate => datadate, :total => values[:total], :thatday => values[:thatday]}
    end
    
    find_object = self.find(:first, :conditions => findconditions)
    if(find_object.nil?)
      find_object = self.create(createoptions)
    else
      find_object.update_attributes({:total => values[:total],:thatday => values[:thatday]})
    end
    return find_object        
  end
  
  
  def self.all_item_count_for_date(datasource,datadate,datatype,getvalue = 'total',update=false)
    # datasource is expected to be a class
    findconditions = {:datasource_type => datasource.name,:datasource_id => 0, :datatype => datatype, :datadate => datadate}
    if(!update and (dn = self.find(:first, :conditions => findconditions)))
      return dn.send(getvalue)
    end
    
    case datatype
    when 'published articles'
      total = Page.bucketed_as('notnews').all(:conditions => "DATE(pages.source_created_at) <= '#{datadate.to_s(:db)}'").count
      thatday = Page.bucketed_as('notnews').all(:conditions => "DATE(pages.source_created_at) = '#{datadate.to_s(:db)}'").count
    when 'published faqs'
      total = Faq.all(:conditions => "DATE(faqs.source_updated_at) <= '#{datadate.to_s(:db)}'").count
      thatday = Faq.all(:conditions => "DATE(faqs.source_updated_at) = '#{datadate.to_s(:db)}'").count      
    when 'published events'
      total = Event.all(:conditions => "DATE(events.xcal_updated_at) <= '#{datadate.to_s(:db)}'").count
      thatday = Event.all(:conditions => "DATE(events.xcal_updated_at) = '#{datadate.to_s(:db)}'").count      
    when 'published news'
      total = Page.bucketed_as('news').all(:conditions => "DATE(pages.source_created_at) <= '#{datadate.to_s(:db)}'").count
      thatday = Page.bucketed_as('news').all(:conditions => "DATE(pages.source_created_at) = '#{datadate.to_s(:db)}'").count      
    when 'published features'
      total = Page.bucketed_as('feature').all(:conditions => "DATE(pages.source_created_at) <= '#{datadate.to_s(:db)}'").count
      thatday = Page.bucketed_as('feature').all(:conditions => "DATE(pages.source_created_at) = '#{datadate.to_s(:db)}'").count      
    when 'published learning lessons'
      total = Page.bucketed_as('learning lessons').all(:conditions => "DATE(pages.source_created_at) <= '#{datadate.to_s(:db)}'").count
      thatday = Page.bucketed_as('learning lessons').all(:conditions => "DATE(pages.source_created_at) = '#{datadate.to_s(:db)}'").count
    when 'accounts'
      total = User.all(:conditions => "DATE(accounts.created_at) <= '#{datadate.to_s(:db)}'").count
      thatday = User.all(:conditions => "DATE(accounts.created_at) = '#{datadate.to_s(:db)}'").count
    when 'valid accounts'
      total = User.notsystem.validusers.all(:conditions => "DATE(accounts.created_at) <= '#{datadate.to_s(:db)}'").count
      thatday = User.notsystem.validusers.all(:conditions => "DATE(accounts.created_at) = '#{datadate.to_s(:db)}'").count
    else
      return nil
    end
    
    if(dn = DailyNumber.update_or_create(datasource,datatype,datadate,{:total => total, :thatday => thatday}))
      return dn.send(getvalue)
    else
      return nil
    end
  end
  
  def self.community_item_count_for_date(community,datadate,datatype,getvalue = 'total',update=false)
    if(!update and (dn = community.daily_numbers.find_by_datadate_and_datatype(datadate, datatype)))
      return dn.send(getvalue)
    end
    
    case datatype
    when 'published articles'
      total = Page.bucketed_as('notnews').tagged_with_any_content_tags(community.content_tag_names).all(:conditions => "DATE(pages.source_created_at) <= '#{datadate.to_s(:db)}'").count
      thatday = Page.bucketed_as('notnews').tagged_with_any_content_tags(community.content_tag_names).all(:conditions => "DATE(pages.source_created_at) = '#{datadate.to_s(:db)}'").count
    when 'published faqs'
      total = Faq.tagged_with_any_content_tags(community.content_tag_names).all(:conditions => "DATE(faqs.source_updated_at) <= '#{datadate.to_s(:db)}'").count
      thatday = Faq.tagged_with_any_content_tags(community.content_tag_names).all(:conditions => "DATE(faqs.source_updated_at) = '#{datadate.to_s(:db)}'").count      
    when 'published events'
      total = Event.tagged_with_any_content_tags(community.content_tag_names).all(:conditions => "DATE(events.xcal_updated_at) <= '#{datadate.to_s(:db)}'").count
      thatday = Event.tagged_with_any_content_tags(community.content_tag_names).all(:conditions => "DATE(events.xcal_updated_at) = '#{datadate.to_s(:db)}'").count      
    when 'published news'
      total = Page.bucketed_as('news').tagged_with_any_content_tags(community.content_tag_names).all(:conditions => "DATE(pages.source_created_at) <= '#{datadate.to_s(:db)}'").count
      thatday = Page.bucketed_as('news').tagged_with_any_content_tags(community.content_tag_names).all(:conditions => "DATE(pages.source_created_at) = '#{datadate.to_s(:db)}'").count      
    when 'published features'
      total = Page.bucketed_as('feature').tagged_with_any_content_tags(community.content_tag_names).all(:conditions => "DATE(pages.source_created_at) <= '#{datadate.to_s(:db)}'").count
      thatday = Page.bucketed_as('feature').tagged_with_any_content_tags(community.content_tag_names).all(:conditions => "DATE(pages.source_created_at) = '#{datadate.to_s(:db)}'").count      
    when 'published learning lessons'
      total = Page.bucketed_as('learning lessons').tagged_with_any_content_tags(community.content_tag_names).all(:conditions => "DATE(pages.source_created_at) <= '#{datadate.to_s(:db)}'").count
      thatday = Page.bucketed_as('learning lessons').tagged_with_any_content_tags(community.content_tag_names).all(:conditions => "DATE(pages.source_created_at) = '#{datadate.to_s(:db)}'").count      
    else
      return nil
    end
    
    if(dn = DailyNumber.update_or_create(community,datatype,datadate,{:total => total, :thatday => thatday}))
      return dn.send(getvalue)
    else
      return nil
    end
  end
  
  # presumes the records have been updated
  def self.all_published_item_counts_for_date(datadate=Date.yesterday,getvalue = 'total')
    returnhash = {}
    published_item_list_string = "#{PUBLISHED_ITEM_TYPES.map{|string| "'#{string}'"}.join(',')}"
    dnlist = self.find(:all, :include => :datasource, :conditions => "DATE(datadate) = '#{datadate.to_s(:db)}' AND datatype IN (#{published_item_list_string})")
    # collapse dnlist to a hash of a hash
    dnlist.each do |dn|
      if(dn.datasource_id == 0)
        if(returnhash[dn.datasource_type].nil?)
          returnhash[dn.datasource_type] = {}
          returnhash[dn.datasource_type][dn.datatype] = dn.send(getvalue)
        else
          returnhash[dn.datasource_type][dn.datatype] = dn.send(getvalue)
        end
      else
        if(returnhash[dn.datasource].nil?)
          returnhash[dn.datasource] = {}
          returnhash[dn.datasource][dn.datatype] = dn.send(getvalue)
        else
          returnhash[dn.datasource][dn.datatype] = dn.send(getvalue)
        end
      end
    end
    return returnhash
  end
    
end