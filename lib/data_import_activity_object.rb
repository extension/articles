# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

include DataImportCommon
module DataImportActivityObject
  
  def retrieve_objects(options={})
    mydatabase = self.connection.instance_variable_get("@config")[:database]
    
    activityapplication = options[:activityapplication] || nil
    if(activityapplication.nil?)
      return false
    end
    refreshall = options[:refreshall] || false
    datatype = options[:datatype] || nil  
    if(datatype.nil?)
      return false
    end  

    last_activitysource_at = options[:last_activitysource_at] || nil
    timestampsql = nil 
  
    case activityapplication.activitysourcetype
    when ActivityApplication::WIKIDATABASE
      case datatype
      when 'pages'
        retrievesql = self.wiki_pages_sql(activityapplication,last_activitysource_at,refreshall,datatype)
      when 'deletedpages'
        retrievesql = self.wiki_deletedpages_sql(activityapplication)
      else
        return false
      end
    when ActivityApplication::DATABASE
      case activityapplication.shortname
      when 'aae'
        case datatype
        when 'submittedquestions'
          timestampsql = self.aae_submittedquestions_timestamp_sql(mydatabase)
          retrievesql = self.aae_submittedquestions_sql(activityapplication,last_activitysource_at,refreshall)
        else
          return false
        end
      when 'events'
        case datatype
        when 'eventitems'
          retrievesql = self.events_eventitems_sql(activityapplication,last_activitysource_at,refreshall)
        else
          return false
        end
      when 'faq'
        case datatype
        when 'questions'
          retrievesql = self.faq_questions_sql(activityapplication,last_activitysource_at,refreshall)
        else
          return false
        end
      else
        # do nothing
        return false
      end
    else
      # do nothing
      return false
    end
  
    if(timestampsql.nil?)
      lastupdated = DateTime.now.utc
    else
      if(!(lastupdated = self.execute_timestamp_sql(timestampsql,activityapplication.shortname)))
        return false
      else
        if(!refreshall and !last_activitysource_at.nil?)
          if(lastupdated <= last_activitysource_at)
            return lastupdated
          end
        end
      end
    end  
  
    logger.info "##################### Starting #{activityapplication.shortname} #{datatype} retrieval..."
    # execute sql 
    begin
      self.connection.execute(retrievesql)
    rescue => err
      logger.error "ERROR: Exception raised during #{activityapplication.shortname} #{datatype} retrieval: #{err}"
      return false
    end


    logger.info "##################### Finished #{activityapplication.shortname} #{datatype} retrieval."
    return lastupdated
  end


  # TODO: deal with deleted articles?

  def wiki_deletedpages_sql(wikiapplication)

    mydatabase = self.connection.instance_variable_get("@config")[:database]
    wikidatabase = wikiapplication.activitysource
    entrytype = self.wikiapplication_to_entrytype(wikiapplication)

    wikisql = "SELECT DISTINCT(#{wikidatabase}.archive.ar_page_id) as deleted_page_id"
    wikisql += " FROM #{wikidatabase}.archive LEFT JOIN #{wikidatabase}.page ON #{wikidatabase}.archive.ar_page_id = #{wikidatabase}.page.page_id"
    wikisql += " WHERE #{wikidatabase}.page.page_id IS NULL AND #{wikidatabase}.archive.ar_page_id IS NOT NULL"
  
    objectselectsql = "SELECT #{mydatabase}.activity_objects.id as delete_id FROM #{mydatabase}.activity_objects,(#{wikisql}) as deleted_pages"
    objectselectsql += " WHERE #{mydatabase}.activity_objects.activity_application_id = #{wikiapplication.id} AND #{mydatabase}.activity_objects.foreignid = deleted_pages.deleted_page_id"

    updatesql = "UPDATE #{mydatabase}.activity_objects, (#{objectselectsql}) as delete_objects"
    updatesql += " SET #{mydatabase}.activity_objects.status = 'deleted' WHERE #{mydatabase}.activity_objects.id = delete_objects.delete_id"
  
    return updatesql
  end


  def wiki_pages_sql(wikiapplication,last_activitysource_at=nil,refreshall=false,datatype = 'pages')
    case datatype
    when 'pages'
      mwnamespace = 0
    when 'talkpages'
      mwnamespace = 1
    else
      mwnamespace = 0
    end

    mydatabase = self.connection.instance_variable_get("@config")[:database]
    wikidatabase = wikiapplication.activitysource
    entrytype = self.wikiapplication_to_entrytype(wikiapplication)

    wikisql = "SELECT #{wikidatabase}.page.page_title as page_title,#{wikidatabase}.page.page_namespace as page_namespace,"
    wikisql += "#{wikidatabase}.page.page_id as page_id, MAX(TIMESTAMP(#{wikidatabase}.revision.rev_timestamp)) as page_updated,"
    wikisql += "MIN(TIMESTAMP(#{wikidatabase}.revision.rev_timestamp)) as page_created"
    if(entrytype == ActivityObject::COPWIKI_PAGE)
      wikisql += ",#{wikidatabase}.peerpublisher.rev_id as published_revision"
    end
    wikisql += " FROM #{wikidatabase}.revision, #{wikidatabase}.page"
    if(entrytype == ActivityObject::COPWIKI_PAGE)
      wikisql += " LEFT JOIN #{wikidatabase}.peerpublisher on #{wikidatabase}.page.page_id = #{wikidatabase}.peerpublisher.page_id"
    end
    wikisql += " WHERE #{wikidatabase}.revision.rev_page = #{wikidatabase}.page.page_id"
    wikisql += " AND #{wikidatabase}.page.page_namespace  = #{mwnamespace}"
    if(!refreshall and !last_activitysource_at.nil?)
      compare_time_string = last_activitysource_at.strftime("%Y-%m-%d %H:%M:%S")
      wikisql +=  " AND TIMESTAMP(#{wikidatabase}.revision.rev_timestamp) >= '#{compare_time_string}'"
    end
    wikisql += " GROUP BY #{wikidatabase}.page.page_id"
  
    sql = "INSERT INTO #{mydatabase}.activity_objects (activity_application_id,entrytype,namespace,foreignid,displaytitle,fulltitle,status,created_at,updated_at)"
    sql +=  " SELECT #{wikiapplication.id}, #{entrytype}, wikisourcedata.page_namespace,wikisourcedata.page_id,CAST(wikisourcedata.page_title AS BINARY),"
    sql +=  "CAST(wikisourcedata.page_title AS BINARY),"
    if(entrytype == ActivityObject::COPWIKI_PAGE)
      sql += "IF(wikisourcedata.published_revision > 0,'published','active'),"
    else
      sql += "'active',"
    end
    sql += "wikisourcedata.page_created,wikisourcedata.page_updated"
    sql +=  " FROM (#{wikisql}) as wikisourcedata"
    if(entrytype == ActivityObject::COPWIKI_PAGE)
      sql +=  " ON DUPLICATE KEY UPDATE #{mydatabase}.activity_objects.updated_at = wikisourcedata.page_updated, #{mydatabase}.activity_objects.status = IF(wikisourcedata.published_revision > 0,'published','active')"
    else
      sql +=  " ON DUPLICATE KEY UPDATE #{mydatabase}.activity_objects.updated_at = wikisourcedata.page_updated"
    end
    return sql
  end

  def events_eventitems_sql(eventapplication,last_activitysource_at=nil,refreshall=false)
    mydatabase = self.connection.instance_variable_get("@config")[:database]
    eventdatabase = eventapplication.activitysource      

    sql = "INSERT INTO #{mydatabase}.activity_objects (activity_application_id,entrytype,namespace,foreignid,displaytitle,fulltitle,status,created_at,updated_at)"
    sql +=  " SELECT #{eventapplication.id}, #{ActivityObject::EVENT},#{ActivityObject::NS_DEFAULT},#{eventdatabase}.events.id,"
    sql += "CAST((SUBSTRING(#{eventdatabase}.events.title,1,255)) AS BINARY),CAST(#{eventdatabase}.events.title AS BINARY),"
    sql += "IF((#{eventdatabase}.events.deleted = 1),'deleted','published'),#{eventdatabase}.events.created_at,#{eventdatabase}.events.updated_at"
    sql +=  " FROM #{eventdatabase}.events"
    if(!refreshall and !last_activitysource_at.nil?)
      compare_time_string = last_activitysource_at.strftime("%Y-%m-%d %H:%M:%S")
      sql +=  " WHERE #{eventdatabase}.events.updated_at >= '#{compare_time_string}'"
    end
    sql +=  " ON DUPLICATE KEY UPDATE #{mydatabase}.activity_objects.updated_at = #{eventdatabase}.events.updated_at,#{mydatabase}.activity_objects.status = IF((#{eventdatabase}.events.deleted = 1),'deleted','published')"
  
    return sql
  end

  def aae_submittedquestions_timestamp_sql(activitydatabase)
    timestampsql = "SELECT MAX(#{activitydatabase}.submitted_questions.updated_at) as last_updated_time FROM #{activitydatabase}.submitted_questions"
    return timestampsql
  end

  def aae_submittedquestions_sql(aaeapplication,last_activitysource_at=nil,refreshall=false)
      mydatabase = self.connection.instance_variable_get("@config")[:database]
      aaedatabase = mydatabase

      sql = "INSERT INTO #{mydatabase}.activity_objects (activity_application_id,entrytype,namespace,foreignid,source,displaytitle,fulltitle,status,created_at,updated_at,sourcewidget)"
      sql +=  " SELECT #{aaeapplication.id}, #{ActivityObject::AAE},#{ActivityObject::NS_DEFAULT},#{aaedatabase}.submitted_questions.id,#{aaedatabase}.submitted_questions.external_app_id,"
      sql += "SUBSTRING(#{aaedatabase}.submitted_questions.asked_question,1,255),#{aaedatabase}.submitted_questions.asked_question,"
      sql += "#{aaedatabase}.submitted_questions.status,#{aaedatabase}.submitted_questions.created_at,#{aaedatabase}.submitted_questions.updated_at,#{aaedatabase}.submitted_questions.widget_name"
      sql +=  " FROM #{aaedatabase}.submitted_questions"
      if(!refreshall and !last_activitysource_at.nil?)
        compare_time_string = last_activitysource_at.strftime("%Y-%m-%d %H:%M:%S")
        sql +=  " WHERE #{aaedatabase}.submitted_questions.updated_at >= '#{compare_time_string}'"
      end
      sql +=  " ON DUPLICATE KEY UPDATE #{mydatabase}.activity_objects.updated_at = #{aaedatabase}.submitted_questions.updated_at,"
      sql +=  "#{mydatabase}.activity_objects.status = #{aaedatabase}.submitted_questions.status,"
      sql +=  "#{mydatabase}.activity_objects.source = #{aaedatabase}.submitted_questions.external_app_id,"
      sql +=  "#{mydatabase}.activity_objects.sourcewidget = #{aaedatabase}.submitted_questions.widget_name,"
      sql +=  "#{mydatabase}.activity_objects.displaytitle = SUBSTRING(#{aaedatabase}.submitted_questions.asked_question,1,255), "
      sql +=  "#{mydatabase}.activity_objects.fulltitle = #{aaedatabase}.submitted_questions.asked_question"

    return sql
  end
  

  def faq_questions_sql(faqapplication,last_activitysource_at=nil,refreshall=false)
    mydatabase = self.connection.instance_variable_get("@config")[:database]
    faqdatabase = faqapplication.activitysource
        
    sql = "INSERT INTO #{mydatabase}.activity_objects (activity_application_id,entrytype,namespace,foreignid,foreignrevision,displaytitle,fulltitle,status,created_at,updated_at)"
    sql +=  " SELECT #{faqapplication.id}, #{ActivityObject::FAQ},#{ActivityObject::NS_DEFAULT},#{faqdatabase}.questions.id,#{faqdatabase}.revisions.id,"
    sql += "CAST((SUBSTRING(#{faqdatabase}.revisions.question_text,1,255)) AS BINARY),CAST(#{faqdatabase}.revisions.question_text AS BINARY),"
    sql += "#{faqdatabase}.questions.status,#{faqdatabase}.questions.created_at,#{faqdatabase}.questions.updated_at"
    sql +=  " FROM #{faqdatabase}.questions, #{faqdatabase}.revisions"
    sql +=  " WHERE #{faqdatabase}.questions.current_revision_id = #{faqdatabase}.revisions.id"
    if(!refreshall and !last_activitysource_at.nil?)
      compare_time_string = last_activitysource_at.strftime("%Y-%m-%d %H:%M:%S")
      sql +=  " AND #{faqdatabase}.questions.updated_at >= '#{compare_time_string}'"
    end
    sql +=  " ON DUPLICATE KEY UPDATE #{mydatabase}.activity_objects.updated_at = #{faqdatabase}.questions.updated_at, #{mydatabase}.activity_objects.status = #{faqdatabase}.questions.status,"
    sql +=  "#{mydatabase}.activity_objects.displaytitle = CAST((SUBSTRING(#{faqdatabase}.revisions.question_text,1,255)) AS BINARY), "
    sql +=  "#{mydatabase}.activity_objects.fulltitle = CAST(#{faqdatabase}.revisions.question_text AS BINARY) "
  
    return sql
  end

end