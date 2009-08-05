# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class DailyNumber < ActiveRecord::Base
  belongs_to :datasource, :polymorphic => true
  
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
      total = Article.all(:conditions => "DATE(articles.wiki_created_at) <= '#{datadate.to_s(:db)}'").count
      thatday = Article.all(:conditions => "DATE(articles.wiki_created_at) = '#{datadate.to_s(:db)}'").count
    when 'published faqs'
      total = Faq.all(:conditions => "DATE(faqs.heureka_published_at) <= '#{datadate.to_s(:db)}'").count
      thatday = Faq.all(:conditions => "DATE(faqs.heureka_published_at) = '#{datadate.to_s(:db)}'").count      
    when 'published events'
      total = Event.all(:conditions => "DATE(events.xcal_updated_at) <= '#{datadate.to_s(:db)}'").count
      thatday = Event.all(:conditions => "DATE(events.xcal_updated_at) = '#{datadate.to_s(:db)}'").count      
    when 'published news'
      total = Article.bucketed_as('news').all(:conditions => "DATE(articles.wiki_created_at) <= '#{datadate.to_s(:db)}'").count
      thatday = Article.bucketed_as('news').all(:conditions => "DATE(articles.wiki_created_at) = '#{datadate.to_s(:db)}'").count      
    when 'published features'
      total = Article.bucketed_as('feature').all(:conditions => "DATE(articles.wiki_created_at) <= '#{datadate.to_s(:db)}'").count
      thatday = Article.bucketed_as('feature').all(:conditions => "DATE(articles.wiki_created_at) = '#{datadate.to_s(:db)}'").count      
    when 'published learning lessons'
      total = Article.bucketed_as('learning lessons').all(:conditions => "DATE(articles.wiki_created_at) <= '#{datadate.to_s(:db)}'").count
      thatday = Article.bucketed_as('learning lessons').all(:conditions => "DATE(articles.wiki_created_at) = '#{datadate.to_s(:db)}'").count
    when 'accounts'
      total = User.all(:conditions => "DATE(users.created_at) <= '#{datadate.to_s(:db)}'").count
      thatday = User.all(:conditions => "DATE(users.created_at) = '#{datadate.to_s(:db)}'").count
    when 'valid accounts'
      total = User.validusers.all(:conditions => "DATE(users.created_at) <= '#{datadate.to_s(:db)}'").count
      thatday = User.validusers.all(:conditions => "DATE(users.created_at) = '#{datadate.to_s(:db)}'").count
    else
      return nil
    end
    
    if(dn = DailyNumber.update_or_create(datasource,datatype,datadate,{:total => total, :thatday => thatday}))
      return dn.send(getvalue)
    else
      return nil
    end
  end  
    
end