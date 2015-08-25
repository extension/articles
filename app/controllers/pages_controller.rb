# === COPYRIGHT:
#  Copyright (c) 2005-2011 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class PagesController < ApplicationController
  layout 'frontporch'
  before_filter :force_html_format
  before_filter :set_content_tag_and_community_and_topic
  before_filter :signin_optional

  def redirect_article
    # folks chop off the page name and expect the url to give them something
    if not (params[:title] or params[:id])
      redirect_to site_articles_url(with_content_tag?), :status=>301
      return
    end

    # get the title out, find it, and redirect
    if params[:title]
      raw_title_to_lookup = CGI.unescape(request.fullpath.gsub('/pages/', ''))
      # comes in double-escaped from apache to handle the infamous '?'
      raw_title_to_lookup = CGI.unescape(raw_title_to_lookup)
      # why is this?
      raw_title_to_lookup.gsub!('??.html', '?')

      # special handling for mediawiki-like "Categoy:bob" - style titles
      if raw_title_to_lookup =~ /Category\:(.+)/
        content_tag = $1.gsub(/_/, ' ')
        redirect_to category_tag_index_url(:content_tag => content_tag_url_display_name(content_tag)), :status=>301
        return
      end

      if raw_title_to_lookup =~ /\/print(\/)?$/
        print = true
        raw_title_to_lookup.gsub!(/\/print(\/)?$/, '')
      end

      # try and handle googlebot urls that have the page params on the end for redirection (new urls automatically handled)
      (title_to_lookup,blah) = raw_title_to_lookup.split(%r{(.+)\?})[1,2]
      if(!title_to_lookup)
        title_to_lookup = raw_title_to_lookup
      end

      @page = Page.find_by_legacy_title_from_url(title_to_lookup)
    elsif(params[:id])
      if(params[:print])
        print = true
      end
      @page = Page.find_by_id(params[:id])
    end

    if @page
      if(print)
        redirect_to(print_page_url(:id => @page.id, :title => @page.url_title), :status => :moved_permanently)
      else
        redirect_to(page_url(:id => @page.id, :title => @page.url_title), :status => :moved_permanently)
      end
    else
      @missing = title_to_lookup
      do_404
      return
    end
  end

  def redirect_faq
    # folks chop off the page name and expect the url to give them something
    if (!params[:id])
      redirect_to site_faqs_url(with_content_tag?), :status=>301
      return
    end
    if(params[:print])
      print = true
    end
    @page = Page.faqs.find_by_migrated_id(params[:id])
    if @page
      if(print)
        redirect_to(print_page_url(:id => @page.id, :title => @page.url_title), :status => :moved_permanently)
      else
        redirect_to(page_url(:id => @page.id, :title => @page.url_title), :status => :moved_permanently)
      end
    else
      return do_404
    end
  end

  def show
    # folks chop off the page name and expect the url to give them something
    if (!params[:id])
      redirect_to site_articles_url(with_content_tag?), :status=>301
      return
    end

    @page = Page.find_by_id(params[:id])
    if @page
      @published_content = true
    elsif(page_rediect = PageRedirect.where(redirect_page_id: params[:id]).first)
      return redirect_to(page_url(:id => page_rediect.page.id, :title => page_rediect.page.url_title), status: :moved_permanently)
    elsif(oei = OldEventId.where(event_id: params[:id]).first)
      return redirect_to(Settings.learn_site,:status => :moved_permanently)
    else
      return do_404
    end

    # redirect to learn
    if(@page.is_event?)
      return redirect_to(Settings.events_relocation_url,:status => :moved_permanently)
    end

    # set canonical_link
    @canonical_link = page_url(:id => @page.id, :title => @page.url_title)

    # flag check
    if(check_flags)
      return redirect_to(@canonical_link)
    end

    # special redirect check
    if(@page.is_special_page? and @special_page = SpecialPage.find_by_page_id(@page.id))
      return redirect_to(main_special_url(:path => @special_page.path),:status => :moved_permanently)
    end

    # redirect check
    if(!params[:title] or params[:title] != @page.url_title)
      return redirect_to(@canonical_link,:status => :moved_permanently)
    end



    # get the tags on this article that correspond to community content tags
    @page_tag_names = @page.tag_names
    @page_bucket_names = @page.content_buckets.map(&:name)

    if(!@page_tag_names.blank?)
      # indexed check to set the meta tags for noindex
      @published_content = false if (@page.indexed == Page::NOT_INDEXED)

      # get the tags on this article that are content tags on communities
      @community_tag_names = @page.community_tag_names

      if(!@community_tag_names.blank?)
        @sponsors = Sponsor.tagged_with_any(@community_tag_names).prioritized
        # loop through the list, and see if one of these matches my @community already
        # if so, use that, else, just use the first in the list
        use_content_tag_name = @community_tag_names.sample
        @community_tag_names.each do |community_content_tag_name|
          if(@community and @community.tag_names.include?(community_content_tag_name))
            use_content_tag_name = community_content_tag_name
          end
        end

        use_content_tag = Tag.find_by_name(use_content_tag_name)
        @community = use_content_tag.content_community
        @in_this_section = Page.contents_for_content_tag({:content_tag => use_content_tag})  if @community

        @page_communities = []
        @community_tag_names.each do |tagname|
          if(tag = Tag.find_by_name(tagname))
            if(community = tag.content_community)
              @page_communities << community
            end
          end
        end
      end
    end
    set_title("#{@page.title}")

    # link for Ask an Expert group form
    if(@community and @community.aae_group_id.present?)
      @ask_two_point_oh_form = "#{@community.ask_an_expert_group_url}/ask"
    else
      @ask_two_point_oh_form = Settings.ask_two_point_oh_form
    end

    @donation_block = false
    if(@community and @community.show_donation.present?)
      @donation_block = true
    end
    if use_content_tag
      @learn_event_widget_url = "https://learn.extension.org/widgets/upcoming.js?tags=#{use_content_tag.name}&showdate_on_past_events=false"
    else
      @learn_event_widget_url = "https://learn.extension.org/widgets/front_porch.js"
    end


    if(!@community_tag_names.blank? and !@page_tag_names.blank?)
      flash.now[:googleanalytics] = @page.id_and_link(true,{:tags => @page_tag_names.join(',').gsub(' ','_'), :content_types => @page.datatype.downcase})
      flash.now[:googleanalyticsresourcearea] = @community_tag_names[0].gsub(' ','_')
    end
  end

  def list
    @list_content = true # don't index this page

    @filteredparameters = ParamsFilter.new([:tags,{:content_types => {:default => 'articles,faqs'}},{:articlefilter => :string},:order],params)
    if(!@filteredparameters.order.nil?)
      # validate order
      return do_404 unless Page.orderings.has_value?(@filteredparameters.order)
      @order = @filteredparameters.order
    end

    # empty tags? - presume "all"
    if(@filteredparameters.tags.nil?)
       alltags = true
       content_tags = ['all']
    else
       taglist_operator = @filteredparameters._tags.taglist_operator
       alltags = (@filteredparameters.tags.include?('all'))
       if(alltags)
         content_tags = ['all']
       else
         content_tags = @filteredparameters.tags
       end
    end

    pagelist_scope = Page.scoped({})
    if(!alltags)
      if(taglist_operator and taglist_operator == 'and')
        pagelist_scope = pagelist_scope.tagged_with(content_tags)
      else
        pagelist_scope = pagelist_scope.tagged_with_any(content_tags)
      end
    end

    if(@filteredparameters.content_types)
      content_type_conditions = Page.content_type_conditions(@filteredparameters.content_types,{:allevents => true})
      if(!content_type_conditions.blank?)
         pagelist_scope = pagelist_scope.where(content_type_conditions)
      end
    end

     if(!@filteredparameters.articlefilter.nil?)
      case @filteredparameters.articlefilter
      when 'all'
        @articlefilter = 'All'
      when 'feature'
        @articlefilter = 'Feature'
        bucket = 'feature'
      when 'learning lessons'
        @articlefilter = 'Learning Lesson'
        bucket = 'learning lessons'
      when 'contents'
        @articlefilter = 'Contents'
        bucket = 'contents'
      when 'homage'
        @articlefilter = 'Homage'
        bucket = 'homage'
      end # case statement
      if(!bucket.nil?)
        pagelist_scope = pagelist_scope.bucketed_as(bucket)
      end
    end # @articlefilter.nil?


    titletypes = @filteredparameters.content_types.map{|type| type.capitalize}.join(', ')
    if(!alltags)
      tagstring = content_tags.join(" #{taglist_operator} ")
      @page_title = "#{titletypes} tagged with #{tagstring}"
      @page_title = "#{titletypes} - #{tagstring} - eXtension"
    else
      @page_title = titletypes
      @page_title = "#{titletypes} - all - eXtension"
    end

    if(@order)
      pagelist_scope = pagelist_scope.ordered(@order)
    else
      pagelist_scope = pagelist_scope.ordered
    end
    @pages = pagelist_scope.page(params[:page]).per(100)

  end


  def articles
    redirect_to category_tag_index_url(:content_tag => content_tag_url_display_name(params[:content_tag])), :status=>301
  end

  def learning_lessons
    redirect_to category_tag_index_url(:content_tag => content_tag_url_display_name(params[:content_tag])), :status=>301
  end

  def faqs
    redirect_to category_tag_index_url(:content_tag => content_tag_url_display_name(params[:content_tag])), :status=>301
  end


  def check_flags
    if(params[:paraman] and TRUE_VALUES.include?(params[:paraman]))
      cookies[:paraman] = { :value => true, :expires => 1.hour.from_now }
      true
    elsif(params[:paraman] and FALSE_VALUES.include?(params[:paraman]))
      cookies.delete :paraman
      true
    else
      false
    end
  end


end
