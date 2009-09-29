# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

include DataImportCommon
module DataImportActivity


  def retrieve_activity(options={})
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
    
    case activityapplication.activitysourcetype
    when ActivityApplication::WIKIDATABASE
      case datatype
      when 'editpage'
        timestampsql = self.wiki_page_timestamp_sql(activityapplication.activitysource)
        retrievesql = self.wiki_edit_sql(activityapplication,last_activitysource_at,refreshall,datatype)
      when 'publish'
        if(activityapplication.shortname == 'copwiki')
          timestampsql = self.copwiki_publish_timestamp_sql(activityapplication.activitysource)
          retrievesql = self.copwiki_publish_sql(activityapplication,last_activitysource_at,refreshall)
        else
          return false
        end
      else
        return false
      end
    when ActivityApplication::DATABASE
      case activityapplication.shortname
      when 'events'
        case datatype
        when 'edit'
          timestampsql = self.event_edit_timestamp_sql(activityapplication.activitysource)
          retrievesql = self.event_edit_sql(activityapplication,last_activitysource_at,refreshall)
        else
          return false
        end
      when 'faq'
        case datatype
        when 'edit'
          timestampsql = self.faq_edit_timestamp_sql(activityapplication.activitysource)
          retrievesql = self.faq_edit_sql(activityapplication,last_activitysource_at,refreshall)
        when 'publish'
          timestampsql = self.faq_publish_timestamp_sql(activityapplication.activitysource)
          retrievesql = self.faq_publish_sql(activityapplication,last_activitysource_at,refreshall)            
        else
          return false
        end
      when 'aae'
        case datatype
        when 'submission'
          timestampsql = self.aae_submissions_timestamp_sql(mydatabase)
          retrievesql = self.aae_submissions_sql(activityapplication,last_activitysource_at,refreshall)
        when 'activity'
          timestampsql = self.aae_activity_timestamp_sql(mydatabase)
          retrievesql = self.aae_activity_sql(activityapplication,last_activitysource_at,refreshall)
        else
          return false
        end
      when 'justcode'
        case datatype
        when 'changeset'
          timestampsql = self.justcode_changeset_timestamp_sql(activityapplication.activitysource)
          retrievesql = self.justcode_changeset_sql(activityapplication,last_activitysource_at,refreshall)
        else
          return false
        end
      else
        return false
      end
    when ActivityApplication::FILE
      case activityapplication.shortname
      when 'lists'
      
      else
        return false
      end
    else # application type
      # do nothing
      return false
    end
    
    if(lastupdated = self.execute_timestamp_sql(timestampsql,activityapplication.shortname))
      if(!refreshall and !last_activitysource_at.nil?)
        if(lastupdated <= last_activitysource_at)
          return lastupdated
        end
      end
      
      logger.info "##################### Starting #{activityapplication.shortname} #{datatype} retrieval..."
      # execute retrsql 
      begin
        self.connection.execute(retrievesql)
      rescue => err
        logger.error "ERROR: Exception raised during #{activityapplication.shortname} #{datatype} retrieval: #{err}"
        return false
      end
  
      logger.info "##################### Finished #{activityapplication.shortname} #{datatype} retrieval."
      return lastupdated
    else
      return false
    end
  end

  ############ timestamp sql statements
  def wiki_edit_timestamp_sql(activitydatabase,mwnamespace)    
    timestampsql = "SELECT MAX(TIMESTAMP(#{activitydatabase}.revision.rev_timestamp)) as last_updated_time"
    timestampsql += " FROM #{activitydatabase}.revision, #{activitydatabase}.page"
    timestampsql += " WHERE #{activitydatabase}.revision.rev_page = #{activitydatabase}.page.page_id"
    timestampsql += " AND #{activitydatabase}.page.page_namespace = #{mwnamespace}"
    return timestampsql
  end

  def wiki_talk_timestamp_sql(activitydatabase)
    return self.wiki_edit_timestamp_sql(activitydatabase,1)
  end

  def wiki_page_timestamp_sql(activitydatabase)
    return self.wiki_edit_timestamp_sql(activitydatabase,0)
  end

  def event_edit_timestamp_sql(activitydatabase)
    timestampsql = "SELECT MAX(#{activitydatabase}.event_updates.created_at) as last_updated_time FROM #{activitydatabase}.event_updates"
    return timestampsql
  end

  def faq_edit_timestamp_sql(activitydatabase)
    timestampsql = "SELECT MAX(#{activitydatabase}.revisions.created_at) as last_updated_time FROM #{activitydatabase}.revisions"
    return timestampsql
  end

  def aae_activity_timestamp_sql(activitydatabase)
    timestampsql = "SELECT MAX(#{activitydatabase}.submitted_question_events.created_at) as last_updated_time FROM #{activitydatabase}.submitted_question_events"
    return timestampsql
  end

  def aae_submissions_timestamp_sql(activitydatabase)
    timestampsql = "SELECT MAX(#{activitydatabase}.submitted_questions.created_at) as last_updated_time FROM #{activitydatabase}.submitted_questions"
    return timestampsql
  end

  def justcode_changeset_timestamp_sql(activitydatabase)
    timestampsql = "SELECT MAX(#{activitydatabase}.changesets.committed_on) as last_updated_time FROM #{activitydatabase}.changesets"
    return timestampsql
  end  

  def copwiki_publish_timestamp_sql(activitydatabase)
    timestampsql = "SELECT MAX(#{activitydatabase}.peerpublisher_events.created) as last_updated_time FROM #{activitydatabase}.peerpublisher_events"
    return timestampsql
  end

  def faq_publish_timestamp_sql(activitydatabase)
    timestampsql = "SELECT MAX(#{activitydatabase}.question_events.created_at) as last_updated_time FROM #{activitydatabase}.question_events"
    timestampsql += " WHERE #{activitydatabase}.question_events.description = 'published'"
    return timestampsql
  end

  def copwiki_publish_sql(activityapplication,last_activitysource_at=nil,refreshall=false)
    mydatabase = self.connection.instance_variable_get("@config")[:database]
    activitydatabase = activityapplication.activitysource

    # build sql 
    sql = "INSERT IGNORE INTO #{mydatabase}.#{self.table_name} (created_at,user_id,activitytype,activitycode,activity_application_id,ipaddr,created_by,activity_object_id,privacy)"
    sql +=  " SELECT #{activitydatabase}.peerpublisher_events.created, #{mydatabase}.users.id, #{Activity::INFORMATION}, #{Activity::INFORMATION_PUBLISH},"
    sql +=  "#{activityapplication.id},'unknown',#{mydatabase}.users.id,#{mydatabase}.activity_objects.id,#{Activity::PROTECTED}"
    sql +=  " FROM #{activitydatabase}.peerpublisher_events,  #{mydatabase}.users, #{mydatabase}.activity_objects"
    sql +=  " WHERE #{activitydatabase}.peerpublisher_events.page_id = #{mydatabase}.activity_objects.foreignid"  
    sql +=  " AND #{mydatabase}.activity_objects.entrytype = #{ActivityObject::COPWIKI_PAGE}"  
    sql +=  " AND #{mydatabase}.activity_objects.namespace = #{ActivityObject::NS_DEFAULT}"  
    sql +=  " AND LOWER(#{activitydatabase}.peerpublisher_events.user_name) = LOWER(#{mydatabase}.users.login)"
    if(!refreshall and !last_activitysource_at.nil?)
      compare_time_string = last_activitysource_at.strftime("%Y-%m-%d %H:%M:%S")
      sql +=  " AND #{activitydatabase}.peerpublisher_events.created >= '#{compare_time_string}'"
    else
      sql +=  " AND #{activitydatabase}.peerpublisher_events.created >= '#{Activity::EARLIEST_TRACKED_ACTIVITY_DATE}'"
    end
  
  
    return sql
  end  

  def faq_publish_sql(activityapplication,last_activitysource_at=nil,refreshall=false)
    mydatabase = self.connection.instance_variable_get("@config")[:database]
    activitydatabase = activityapplication.activitysource

    # build sql - ASSUMES FAQ ACCOUNTS == IDENTITY ACCOUNTS!
    sql = "INSERT IGNORE INTO #{mydatabase}.#{self.table_name} (created_at,user_id,activitytype,activitycode,activity_application_id,ipaddr,created_by,activity_object_id,privacy)"
    sql +=  " SELECT #{activitydatabase}.question_events.created_at, #{activitydatabase}.question_events.user_id, #{Activity::INFORMATION}, #{Activity::INFORMATION_PUBLISH},"
    sql +=  "#{activityapplication.id},'unknown',#{activitydatabase}.question_events.user_id,#{mydatabase}.activity_objects.id,#{Activity::PROTECTED}"
    sql +=  " FROM #{activitydatabase}.question_events, #{activitydatabase}.revisions, #{mydatabase}.activity_objects"
    sql +=  " WHERE #{activitydatabase}.question_events.revision_id = #{activitydatabase}.revisions.id"
    sql +=  " AND #{activitydatabase}.question_events.description = 'published'"
    sql +=  " AND #{activitydatabase}.revisions.question_id = #{mydatabase}.activity_objects.foreignid"  
    sql +=  " AND #{mydatabase}.activity_objects.entrytype = #{ActivityObject::FAQ}"  
    sql +=  " AND #{mydatabase}.activity_objects.namespace = #{ActivityObject::NS_DEFAULT}"  
    if(!refreshall and !last_activitysource_at.nil?)
      compare_time_string = last_activitysource_at.strftime("%Y-%m-%d %H:%M:%S")
      sql +=  " AND #{activitydatabase}.question_events.created_at >= '#{compare_time_string}'"
    else
      sql +=  " AND #{activitydatabase}.question_events.created_at >= '#{Activity::EARLIEST_TRACKED_ACTIVITY_DATE}'"
    end

    return sql
  end


  def justcode_changeset_sql(activityapplication,last_activitysource_at=nil,refreshall=false)
    mydatabase = self.connection.instance_variable_get("@config")[:database]
    activitydatabase = activityapplication.activitysource

    # build sql
    sql = "INSERT IGNORE INTO #{mydatabase}.#{self.table_name} (created_at,user_id,activitytype,activitycode,activity_application_id,ipaddr,created_by,activity_object_id,privacy)"
    sql +=  " SELECT #{activitydatabase}.changesets.committed_on, #{mydatabase}.users.id, #{Activity::INFORMATION}, #{Activity::INFORMATION_CHANGESET},"
    sql +=  "#{activityapplication.id},'unknown',#{mydatabase}.users.id,#{mydatabase}.activity_objects.id,#{Activity::PROTECTED}"
    sql +=  " FROM #{activitydatabase}.changesets, #{activitydatabase}.repositories, #{mydatabase}.users, #{mydatabase}.activity_objects"
    sql +=  " WHERE #{activitydatabase}.changesets.committer = #{mydatabase}.users.login" 
    sql +=  " AND #{activitydatabase}.changesets.repository_id = #{activitydatabase}.repositories.id"
    sql +=  " AND #{activitydatabase}.changesets.revision = #{mydatabase}.activity_objects.foreignid"  
    sql +=  " AND #{mydatabase}.activity_objects.entrytype = #{ActivityObject::JUSTCODE_CHANGESET}"  
    sql +=  " AND #{activitydatabase}.repositories.project_id = #{mydatabase}.activity_objects.namespace"  
    if(!refreshall and !last_activitysource_at.nil?)
      compare_time_string = last_activitysource_at.strftime("%Y-%m-%d %H:%M:%S")
      sql +=  " AND #{activitydatabase}.changesets.committed_on >= '#{compare_time_string}'"
    else
      sql +=  " AND #{activitydatabase}.changesets.committed_on >= '#{Activity::EARLIEST_TRACKED_ACTIVITY_DATE}'"
    end
  
    return sql
  end
  
  def event_edit_sql(activityapplication,last_activitysource_at=nil,refreshall=false)
    mydatabase = self.connection.instance_variable_get("@config")[:database]
    activitydatabase = activityapplication.activitysource

    # build sql
    sql = "INSERT IGNORE INTO #{mydatabase}.#{self.table_name} (created_at,user_id,activitytype,activitycode,activity_application_id,ipaddr,created_by,activity_object_id,privacy)"
    sql +=  " SELECT #{activitydatabase}.event_updates.created_at, #{mydatabase}.users.id, #{Activity::INFORMATION}, #{Activity::INFORMATION_EDIT},"
    sql +=  "#{activityapplication.id},'unknown',#{mydatabase}.users.id,#{mydatabase}.activity_objects.id,#{Activity::PROTECTED}"
    sql +=  " FROM #{activitydatabase}.event_updates, #{activitydatabase}.users, #{mydatabase}.users, #{mydatabase}.activity_objects"
    sql +=  " WHERE #{activitydatabase}.event_updates.user_id = #{activitydatabase}.users.id" 
    sql +=  " AND LOWER(#{activitydatabase}.users.extension_id) = LOWER(#{mydatabase}.users.login)"
    sql +=  " AND #{activitydatabase}.event_updates.event_id = #{mydatabase}.activity_objects.foreignid"  
    sql +=  " AND #{mydatabase}.activity_objects.entrytype = #{ActivityObject::EVENT}"  
    sql +=  " AND #{mydatabase}.activity_objects.namespace = #{ActivityObject::NS_DEFAULT}"  
    if(!refreshall and !last_activitysource_at.nil?)
      compare_time_string = last_activitysource_at.strftime("%Y-%m-%d %H:%M:%S")
      sql +=  " AND #{activitydatabase}.event_updates.created_at >= '#{compare_time_string}'"
    else
      sql +=  " AND #{activitydatabase}.event_updates.created_at >= '#{Activity::EARLIEST_TRACKED_ACTIVITY_DATE}'"
    end
  
    return sql
  end

  def wiki_edit_sql(activityapplication,last_activitysource_at=nil,refreshall=false,datatype = 'editpage')
    case datatype
    when 'editpage'
      mwnamespace = 0
    when 'edittalk'
      mwnamespace = 1
    else
      return false
    end
  
    entrytype = ActivityObject.wikiapplication_to_entrytype(activityapplication)
    mydatabase = self.connection.instance_variable_get("@config")[:database]
    activitydatabase = activityapplication.activitysource

    wikisql = "SELECT TIMESTAMP(#{activitydatabase}.revision.rev_timestamp) as timestamp,#{activitydatabase}.page.page_id as pageid, LOWER(#{activitydatabase}.revision.rev_user_text) as userlogin"
    wikisql += " FROM #{activitydatabase}.revision, #{activitydatabase}.page"
    wikisql += " WHERE #{activitydatabase}.revision.rev_page = #{activitydatabase}.page.page_id"
    wikisql += " AND #{activitydatabase}.page.page_namespace = #{mwnamespace}"
    if(!refreshall and !last_activitysource_at.nil?)
      compare_time_string = last_activitysource_at.strftime("%Y-%m-%d %H:%M:%S")
      wikisql +=  " AND TIMESTAMP(#{activitydatabase}.revision.rev_timestamp) >= '#{compare_time_string}'"
    else
      wikisql +=  " AND TIMESTAMP(#{activitydatabase}.revision.rev_timestamp) >= '#{Activity::EARLIEST_TRACKED_ACTIVITY_DATE}'"
    end
  
    sql = "INSERT IGNORE INTO #{mydatabase}.#{self.table_name} (created_at,user_id,activitytype,activitycode,activity_application_id,ipaddr,created_by,activity_object_id,privacy)"
    sql +=  " SELECT wikisourcedata.timestamp, #{mydatabase}.users.id, #{Activity::INFORMATION}, #{Activity::INFORMATION_EDIT},"
    sql += "#{activityapplication.id},'unknown',#{mydatabase}.users.id,#{mydatabase}.activity_objects.id,#{Activity::PROTECTED}"
    sql +=  " FROM #{mydatabase}.users, #{mydatabase}.activity_objects, (#{wikisql}) as wikisourcedata"
    sql +=  " WHERE wikisourcedata.userlogin = LOWER(#{mydatabase}.users.login)"
    sql +=  " AND wikisourcedata.pageid = #{mydatabase}.activity_objects.foreignid"  
    sql +=  " AND #{mydatabase}.activity_objects.entrytype = #{entrytype}"  
    sql +=  " AND #{mydatabase}.activity_objects.namespace = #{ActivityObject::NS_DEFAULT}"

    return sql
  end

  def faq_edit_sql(activityapplication,last_activitysource_at=nil,refreshall=false)
    mydatabase = self.connection.instance_variable_get("@config")[:database]
    activitydatabase = activityapplication.activitysource

    # build sql - ASSUMES FAQ ACCOUNTS == IDENTITY ACCOUNTS!
    sql = "INSERT IGNORE INTO #{mydatabase}.#{self.table_name} (created_at,user_id,activitytype,activitycode,activity_application_id,ipaddr,created_by,activity_object_id,privacy)"
    sql +=  " SELECT #{activitydatabase}.revisions.created_at, #{activitydatabase}.revisions.user_id, #{Activity::INFORMATION}, #{Activity::INFORMATION_EDIT},"
    sql +=  "#{activityapplication.id},'unknown',#{activitydatabase}.revisions.user_id,#{mydatabase}.activity_objects.id,#{Activity::PROTECTED}"
    sql +=  " FROM #{activitydatabase}.revisions, #{mydatabase}.activity_objects"
    sql +=  " WHERE #{activitydatabase}.revisions.question_id = #{mydatabase}.activity_objects.foreignid"  
    sql +=  " AND #{mydatabase}.activity_objects.entrytype = #{ActivityObject::FAQ}"  
    sql +=  " AND #{mydatabase}.activity_objects.namespace = #{ActivityObject::NS_DEFAULT}"  
    if(!refreshall and !last_activitysource_at.nil?)
      compare_time_string = last_activitysource_at.strftime("%Y-%m-%d %H:%M:%S")
      sql +=  " AND #{activitydatabase}.revisions.created_at >= '#{compare_time_string}'"
    else
      sql +=  " AND #{activitydatabase}.revisions.created_at >= '#{Activity::EARLIEST_TRACKED_ACTIVITY_DATE}'"
    end
  
    return sql
  end

  def aae_submissions_sql(activityapplication,last_activitysource_at=nil,refreshall=false)
      mydatabase = self.connection.instance_variable_get("@config")[:database]
      activitydatabase = mydatabase
      system_user_id = User.systemuser.id

      dtc = "#{activitydatabase}.submitted_questions.external_app_id"
      casestatement = "CASE #{dtc} WHEN 'widget' THEN #{Activity::AAE_SUBMISSION_WIDGET} WHEN 'www.extension.org' THEN #{Activity::AAE_SUBMISSION_PUBSITE} ELSE #{Activity::AAE_SUBMISSION_OTHER} END"

      sql = "INSERT IGNORE INTO #{mydatabase}.#{self.table_name} (created_at,user_id,activitytype,activitycode,activity_application_id,ipaddr,created_by,activity_object_id,privacy)"
      sql +=  " SELECT #{activitydatabase}.submitted_questions.created_at, #{system_user_id}, #{Activity::AAE}, #{casestatement},"
      sql +=  "#{activityapplication.id},#{activitydatabase}.submitted_questions.user_ip,#{system_user_id},"
      sql +=  "#{mydatabase}.activity_objects.id,#{Activity::PROTECTED}"
      sql +=  " FROM #{activitydatabase}.submitted_questions, #{mydatabase}.activity_objects"
      sql +=  " WHERE #{activitydatabase}.submitted_questions.id = #{mydatabase}.activity_objects.foreignid"  
      sql +=  " AND #{mydatabase}.activity_objects.entrytype = #{ActivityObject::AAE}"  
      sql +=  " AND #{mydatabase}.activity_objects.namespace = #{ActivityObject::NS_DEFAULT}"  
      if(!refreshall and !last_activitysource_at.nil?)
        compare_time_string = last_activitysource_at.strftime("%Y-%m-%d %H:%M:%S")
        sql +=  " AND #{activitydatabase}.submitted_questions.created_at >= '#{compare_time_string}'"
      else
        sql +=  " AND #{activitydatabase}.submitted_questions.created_at >= '#{Activity::EARLIEST_TRACKED_ACTIVITY_DATE}'"
      end
    
      return sql        
    end

  def aae_activity_sql(activityapplication,last_activitysource_at=nil,refreshall=false)
    mydatabase = self.connection.instance_variable_get("@config")[:database]
    activitydatabase = mydatabase

    dtc = "#{activitydatabase}.submitted_question_events.event_type"
    casestatement = "CASE #{dtc} WHEN 'resolved by' THEN #{Activity::AAE_RESOLVE} WHEN 'assigned to' THEN #{Activity::AAE_ASSIGN} WHEN 'rejected by' THEN #{Activity::AAE_REJECT} WHEN 'no answer given' THEN #{Activity::AAE_NOANSWER} ELSE #{Activity::AAE_OTHER} END"

    # build sql - ASSUMES FAQ ACCOUNTS == IDENTITY ACCOUNTS!
    sql = "INSERT IGNORE INTO #{mydatabase}.#{self.table_name} (created_at,user_id,activitytype,activitycode,activity_application_id,ipaddr,created_by,colleague_id,activity_object_id,privacy,responsetime)"
    sql +=  " SELECT #{activitydatabase}.submitted_question_events.created_at, #{activitydatabase}.submitted_question_events.initiated_by_id, #{Activity::AAE}, #{casestatement},"
    sql +=  "#{activityapplication.id},'unknown',#{activitydatabase}.submitted_question_events.initiated_by_id,#{activitydatabase}.submitted_question_events.recipient_id,"
    sql +=  "#{mydatabase}.activity_objects.id,#{Activity::PROTECTED},TIMESTAMPDIFF(MINUTE,#{mydatabase}.activity_objects.created_at,#{activitydatabase}.submitted_question_events.created_at)"
    sql +=  " FROM #{activitydatabase}.submitted_question_events, #{mydatabase}.activity_objects"
    sql +=  " WHERE #{activitydatabase}.submitted_question_events.submitted_question_id = #{mydatabase}.activity_objects.foreignid"  
    sql +=  " AND #{mydatabase}.activity_objects.entrytype = #{ActivityObject::AAE}"  
    sql +=  " AND #{mydatabase}.activity_objects.namespace = #{ActivityObject::NS_DEFAULT}"  
    if(!refreshall and !last_activitysource_at.nil?)
      compare_time_string = last_activitysource_at.strftime("%Y-%m-%d %H:%M:%S")
      sql +=  " AND #{activitydatabase}.submitted_question_events.created_at >= '#{compare_time_string}'"
    else
      sql +=  " AND #{activitydatabase}.submitted_question_events.created_at >= '#{Activity::EARLIEST_TRACKED_ACTIVITY_DATE}'"
    end
  
    return sql
  end

end