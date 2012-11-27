# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Api::DataController < ApplicationController
  
  def articlelink
     filteredparams = ParamsFilter.new([{:source_url => :string},{:original_url => :string},:apikey],params)
     apikey = (filteredparams.apikey.nil? ? ApiKey.systemkey : filteredparams.apikey)
     ApiKeyEvent.log_event("#{controller_path}/#{action_name}",apikey)
    
     if(filteredparams.original_url.nil? and filteredparams.source_url.nil? )
       returnhash = {:success => false, :errormessage => 'Not a valid source url'}
       return render :text => returnhash.to_json
     end
     
     if(filteredparams.original_url)
       source_url = filteredparams.original_url
     elsif(filteredparams.source_url)
       source_url = filteredparams.source_url
     end
     
     begin 
       parsed_uri = URI.parse(URI.unescape(source_url))
     rescue
       returnhash = {:success => false, :errormessage => 'Not a valid source url'}
       return render :text => returnhash.to_json
     end
     
     if(parsed_uri.class == URI::Generic)
       find_url = "http://" + parsed_uri.to_s
     elsif(parsed_uri.class == URI::HTTP or parsed_uri.class == URI::HTTPS)
       find_url = parsed_uri.to_s
     else
       returnhash = {:success => false, :errormessage => 'Not a valid original url'}
       return render :text => returnhash.to_json
     end
     
     page = Page.find_by_source_url(find_url)
     if(!page)
        returnhash = {:success => false, :errormessage => 'Unable to find an page corresponding to the given URL'}
        return render :text => returnhash.to_json
     end
     
     returnhash = {}
     returnhash[:title] = page.title
     returnhash[:link] = page.id_and_link
     returnhash[:created] = page.source_created_at
     returnhash[:updated] = page.source_updated_at
     return render :text => returnhash.to_json    
  end

  def publicprofile
    filteredparams = ParamsFilter.new([:person,:apikey],params)
    apikey = (filteredparams.apikey.nil? ? ApiKey.systemkey : filteredparams.apikey)
    # TODO: consider doing this automatically in application_controller as a before_filter
    ApiKeyEvent.log_event("#{controller_path}/#{action_name}",apikey)
    
    if(filteredparams.person.nil?)
      returnhash = {:success => false, :errormessage => 'No such user.'}
      return render :text => returnhash.to_json
    else
      @showuser = filteredparams.person
    end
    
    publicattributes = @showuser.public_attributes
    if(publicattributes.nil?)
      returnhash = {:success => false, :errormessage => 'No public attributes'}
      return render :text => returnhash.to_json
    else
      returnhash = publicattributes.merge({:success => true})
      return render :text => returnhash.to_json
    end
  end

  def communities
    filteredparams = ParamsFilter.new([:apikey,:communitytype],params)
    apikey = (filteredparams.apikey.nil? ? ApiKey.systemkey : filteredparams.apikey)
    # TODO: consider doing this automatically in application_controller as a before_filter
    ApiKeyEvent.log_event("#{controller_path}/#{action_name}",apikey)
  
    returnhash = {:success => true, :communities => {}, :version => 1}
    case filteredparams.communitytype
    when 'all'
      communitylist = Community.all(:order => 'name')      
    when 'approved'
      communitylist = Community.approved.all(:order => 'name')
    when 'institution'
      communitylist = Community.institution.all(:order => 'name')
    when 'usercontributed'
      communitylist = Community.usercontributed.all(:order => 'name')
    when 'launched'
      communitylist = Community.launched.all(:order => 'name')
    when 'publishing'
      communitylist = Community.all(:conditions => ["entrytype = #{Community::APPROVED} or (entrytype = #{Community::USERCONTRIBUTED} and show_in_public_list = 1)"], :order => 'name')      
    else
      returnhash = {:success => false, :errormessage => 'Unrecognized communitytype.'}
      return render :text => returnhash.to_json
    end  
    
    returnhash[:communitycount] = communitylist.length
    communitylist.each do |community|
      returnhash[:communities][community.id] = {}
      # add in the community information
      returnhash[:communities][community.id][:name] = community.name
      returnhash[:communities][community.id][:entrytype] = community.entrytype_to_s 
      returnhash[:communities][community.id][:shortname] = community.shortname if(!community.shortname.blank?)
      returnhash[:communities][community.id][:description] = community.description if(!community.description.blank?)
      returnhash[:communities][community.id][:public_name] = community.public_name if(!community.public_name.blank?)
      returnhash[:communities][community.id][:primary_content_tag_name] = community.primary_content_tag_name if(!community.primary_content_tag_name.blank?)
      returnhash[:communities][community.id][:content_tag_names] = community.content_tag_names if(!community.content_tag_names.blank?)
      returnhash[:communities][community.id][:launched] = true if(community.is_launched?)
    end
    return render :text => returnhash.to_json
  end
  
  def communitymembers
    filteredparams = ParamsFilter.new([:community,:apikey],params)
    apikey = (filteredparams.apikey.nil? ? ApiKey.systemkey : filteredparams.apikey)
    # TODO: consider doing this automatically in application_controller as a before_filter
    ApiKeyEvent.log_event("#{controller_path}/#{action_name}",apikey)
    
  
    if(filteredparams.community.nil?)
      returnhash = {:success => false, :errormessage => 'No such community.'}
      return render :text => returnhash.to_json
    end
    community = filteredparams.community
    joined = community.joined
    
    returnhash = {:success => true, :total_joined => joined.size, :has_public_data => 0, :person_list => {}}  
    joined.each do |u|
      public_attributes_for_user = u.public_attributes
      if(public_attributes_for_user)
        returnhash[:has_public_data] += 1
        returnhash[:person_list][u.login] = public_attributes_for_user
      end
    end

    # add in the community information
    community_info = {}
    community_info[:name] = community.name
    community_info[:entrytype] = community.entrytype_to_s 
    if(!community.shortname.blank?)
      community_info[:shortname] = community.shortname
    end
    if(!community.description.blank?)
      community_info[:description] = community.description
    end
    if(community.is_launched?)
      community_info[:launched] = true
      community_info[:public_name] = community.public_name
      community_info[:primary_content_tag_name] = community.primary_content_tag_name
      community_info[:content_tag_names] = community.content_tag_names
    end
    
    returnhash[:community_info] = community_info

    return render :text => returnhash.to_json
  end
  
  
   def content_titles
      filteredparams = ParamsFilter.new([:apikey,:content_types,:limit,:tags],params)
      apikey = (filteredparams.apikey.nil? ? ApiKey.systemkey : filteredparams.apikey)
      # TODO: consider doing this automatically in application_controller as a before_filter
      ApiKeyEvent.log_event("#{controller_path}/#{action_name}",apikey)
      returnhash = {:success => true, :content_titles => [], :version => 1}
      
      # empty content types? return error
      if(filteredparams.content_types.nil?)
         returnhash = {:success => false, :errormessage => 'Unrecognized content types.'}
         return render :text => returnhash.to_json
      end
      
      if(filteredparams.limit.nil?)
         # empty limit? set to default
         limit = AppConfig.configtable['default_content_limit']
      elsif(filteredparams.limit > AppConfig.configtable['max_content_limit'])
          # limit over? return an error, let's be pedantic
          returnhash = {:success => false, :errormessage => "Requested limit of #{filteredparams.limit} is greater than the max allowed: #{AppConfig.configtable['max_content_limit']}"}
          return render :text => returnhash.to_json
      else
         limit = filteredparams.limit
      end
      
      # empty tags? - presume "all"
      if(filteredparams.tags.nil?)
         alltags = true
         content_tags = ['all']
      else
         tag_operator = filteredparams._tags.taglist_operator      
         content_tags = filteredparams.tags
         alltags = (content_tags.include?('all'))
      end
      
      datatypes = []
      filteredparams.content_types.each do |content_type|
        case content_type
        when 'faqs'
          datatypes << 'Faq'
        when 'articles'
          datatypes << 'Article'
        when 'events'
          datatypes << 'Event'
        when 'news'
          datatypes << 'News'
        end
      end
      
      if(alltags)
         @returnitems = Page.recent_content(:datatypes => datatypes, :limit => limit)
      else
         @returnitems = Page.recent_content(:datatypes => datatypes, :content_tags => content_tags, :limit => limit, :tag_operator => tag_operator, :within_days => AppConfig.configtable['events_within_days'])
      end
                  
      @returnitems.each do |item|
         entry = {}
         entry['id'] = item.id_and_link
         entry['published'] = item.source_created_at.xmlschema
         entry['updated'] = item.source_updated_at.xmlschema
         entry['content_type'] = item.datatype.downcase         
         # TODO? categories
         entry['title'] = item.title
         entry['href'] = item.id_and_link
         returnhash[:content_titles] << entry
      end
      return render :text => returnhash.to_json
   end
      
end