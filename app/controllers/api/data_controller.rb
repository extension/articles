# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Api::DataController < ApplicationController

  def articlelink
     filteredparams = ParamsFilter.new([{:source_url => :string},{:original_url => :string}],params)

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


   def content_titles
      filteredparams = ParamsFilter.new([:content_types,:limit,:tags],params)
      # TODO: consider doing this automatically in application_controller as a before_filter
      returnhash = {:success => true, :content_titles => [], :version => 1}

      # empty content types? return error
      if(filteredparams.content_types.nil?)
         returnhash = {:success => false, :errormessage => 'Unrecognized content types.'}
         return render :text => returnhash.to_json
      end

      if(filteredparams.limit.nil?)
         # empty limit? set to default
         limit = Settings.default_content_limit
      elsif(filteredparams.limit > Settings.max_content_limit)
          # limit over? return an error, let's be pedantic
          returnhash = {:success => false, :errormessage => "Requested limit of #{filteredparams.limit} is greater than the max allowed: #{Settings.max_content_limit}"}
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
        end
      end

      if(alltags)
         @returnitems = Page.recent_content(:datatypes => datatypes, :limit => limit)
      else
         @returnitems = Page.recent_content(:datatypes => datatypes, :content_tags => content_tags, :limit => limit, :tag_operator => tag_operator, :within_days => Settings.events_within_days)
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
