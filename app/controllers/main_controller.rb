# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class MainController < ApplicationController
  before_filter :set_content_tag_and_community_and_topic

  layout 'pubsite'
  
  def index
     @published_content = true  # index the main page
    
     set_title('Objective. Research-based. Credible. Information and tools you can use every day to improve your life.')
     set_titletag('eXtension - Objective. Research-based. Credible.')
     @right_column = false
     @sitehome = true
     @includejquery = true
		sponsorlist = Sponsor.all
     @sponsors = Hash.new
		Sponsor::SPONSORSHIP_LEVELS.each{ |level| @sponsors[level] = Array.new}
		sponsorlist.each{ |sponsor| @sponsors[sponsor.level] << sponsor if sponsor.level}
     
     # get diverse list of articles across different communities
     @community_highlights = Page.diverse_feature_list({:limit => 6})

     @recent_content = Page.recent_content({:datatypes => ['Article','Faq','News'], :limit => 10})
     @ask_two_point_oh_form = AppConfig.configtable['ask_two_point_oh_form']
   end
   
  def category_tag
      
    if(!@community.nil?)
      return redirect_to site_index_url(:content_tag => content_tag_url_display_name(params[:content_tag])), :status=>301
      # check for CategoryTagRedirect
    elsif(redirect = CategoryTagRedirect.where("term = ?",params[:content_tag].downcase).first)
      return redirect_to(redirect.target_url, :status=>301)  
    elsif(!canonicalized_category?(params[:content_tag]))
      return redirect_to category_tag_index_url(:content_tag => content_tag_url_display_name(params[:content_tag])), :status=>301
    end  
    
    
    if(!@content_tag.nil?)
      set_title("Content tagged with:", @content_tag.name.titleize)
      set_titletag("Content tagged with '#{@content_tag.name}'  - eXtension")
      @youth = true if @content_tag.name == 'youth'
      @right_column = true
    else
      set_title("All Content")
      set_titletag("All Content - eXtension")  
    end
    
   
    if(@content_tag.nil?)
      @news = Page.recent_content({:datatypes => ['News'], :limit => 3})
      @recent_learning_lessons = Page.main_lessons_list({:limit => 3})
      @faqs = Page.recent_content({:datatypes => ['Faq'], :limit => 3})
      @articles = Page.ordered(Page.orderings['Newest to oldest']).limit(3)
    else
      @canonical_link = category_tag_index_url(:content_tag => @content_tag.url_display_name)      
      @news = Page.recent_content({:datatypes => ['News'], :content_tag => @content_tag, :limit => 3})
      @recent_learning_lessons = Page.main_lessons_list({:content_tag => @content_tag, :limit => 3})
      @faqs = Page.recent_content({:datatypes => ['Faq'], :content_tags => [@content_tag], :limit => 3})
      @newsicles = Page.recent_content({:datatypes => ['Article','News'], :content_tags => [@content_tag], :limit => 8}) unless @community
      @recent_newsicles= Page.recent_content({:datatypes => ['Article','News'], :content_tags => [@content_tag], :limit => 3}) unless @in_this_section
    end
        
    return render(:template => 'main/category_landing') 
    
  end
  
  def community_tag
    @published_content = true  # index CoP landing pages
    
    if(@community.nil?)
      # check for CategoryTagRedirect
      if(redirect = CategoryTagRedirect.where("term = ?",params[:content_tag].downcase).first)
        return redirect_to(redirect.target_url, :status=>301)
      else
        return redirect_to category_tag_index_url(:content_tag => content_tag_url_display_name(params[:content_tag])), :status=>301
      end
    elsif(!canonicalized_category?(params[:content_tag]))
      return redirect_to site_index_url(:content_tag => content_tag_url_display_name(params[:content_tag])), :status=>301
    end
    
    if(@community and @community.aae_group_id.present?)
      @ask_two_point_oh_form = "#{@community.ask_an_expert_group_url}/ask"
    else
      @ask_two_point_oh_form = AppConfig.configtable['ask_two_point_oh_form']
    end
    
    set_title(@community.public_name,@community.public_description)
    set_titletag("#{@community.public_name} - eXtension")
    @canonical_link = site_index_url(:content_tag => @content_tag.url_display_name)      
    community_content_tag_names = @community.content_tag_names
    @sponsors = Sponsor.tagged_with_any_content_tags(community_content_tag_names).prioritized
    @in_this_section = Page.contents_for_content_tag({:content_tag => @content_tag})
    @community_highlights = Page.main_feature_list({:content_tag => @content_tag, :limit => 8})
    @youth = true if @topic and @topic.name == 'Youth'
    flash.now[:googleanalytics] = "/" + @content_tag.name.gsub(' ','_')
    flash.now[:googleanalyticsresourcearea] = @content_tag.name.gsub(' ','_')


    @news = Page.recent_content({:datatypes => ['News'], :content_tag => @content_tag, :limit => 3})
    @recent_learning_lessons = Page.main_lessons_list({:content_tag => @content_tag, :limit => 3})
    @faqs = Page.recent_content({:datatypes => ['Faq'], :content_tags => [@content_tag], :limit => 3})
    @newsicles = Page.recent_content({:datatypes => ['Article','News'], :content_tags => [@content_tag], :limit => 8}) unless @community
    @recent_newsicles= Page.recent_content({:datatypes => ['Article','News'], :content_tags => [@content_tag], :limit => 3}) unless @in_this_section

    return render(:template => 'main/community_landing') 
  end
  
  def legacy_events_redirect
    if(@content_tag)
      redirect_params = {:content_tag => @content_tag.url_display_name, :year => params[:year], :month => params[:month], :event_state => params[:event_state]}
    else
      redirect_params = {:content_tag => 'all', :year => params[:year], :month => params[:month], :event_state => params[:event_state]}
    end
    
    return redirect_to site_events_url(redirect_params), :status=>301
  end
  
  def search
    @right_column = false
    @ask_two_point_oh_form = AppConfig.configtable['ask_two_point_oh_form']
    set_title("Search results")
    set_titletag("eXtension - Search results")
  end
  
  def communities
    @published_content = true
    @canonical_link = main_communities_url
    @right_column = false
    @special_page = SpecialPage.find_by_path('communities')
    @page = @special_page.page
    set_title(@special_page.main_heading, @special_page.sub_heading)
    set_titletag(@special_page.titletag)
    @communities = Community.launched.ordered_by_topic
  end
  
  def special
    path = params[:path]
    if(!path or !@special_page = SpecialPage.find_by_path(path))
      return do_404
    end

    @published_content = true
    @canonical_link = main_special_url(:path => @special_page.path)
    @right_column = false
    @page = @special_page.page
    set_title(@special_page.main_heading, @special_page.sub_heading)
    set_titletag(@special_page.titletag)
  end

    
  def show_institution_list
    if params[:zip_or_state]
      if params[:zip_or_state].to_i > 0
        state = to_state(params[:zip_or_state].to_i)
      else
        state = params[:zip_or_state].upcase
      end
      if(!(location = Location.find_by_abbreviation(state)))
        render(:update) do |page| 
          page.replace_html "logo", :partial =>  "shared/no_institution"
        end
        return
      else
        public_institutions_for_location = location.communities.institutions.public_list
        if(!public_institutions_for_location.blank?)
          if(public_institutions_for_location.length == 1)
            @personal[:institution] = public_institutions_for_location[0]
            @personal[:location] = location
            session[:location_and_county] = {:location_id => location.id}
            session[:institution_community_id] = @personal[:institution].id.to_s
            session[:multistate] = nil
            render(:update) do |page| 
              page.replace_html "logo", :partial =>  "shared/logo"
            end
            return
          else
            render(:update) do |page| 
              page.replace_html "logo", :partial => "shared/multistate", :locals => {:institutions => public_institutions_for_location}
            end
            return
          end
        else
          render(:update) do |page| 
            page.replace_html "logo", :partial =>  "shared/no_institution"
          end
          return
        end
      end
    end
    render :nothing => true
  end
  
  def set_institution
    if(institution = Community.find_by_id(params[:institution_id]))
      session[:institution_community_id] = institution.id
      session[:location_and_county] = {:location_id => institution.location.id}
      session[:multistate] = nil
    end
    request.env["HTTP_REFERER"] ? (redirect_to :back) : (redirect_to home_url) 
  end
  
  private
    
  def checklogin
    if session[:user]
      checkuser = User.find_by_id(session[:user])
      if not checkuser
        return false
      else
        @user = checkuser
        return true
      end
    else
      return false
    end
  end


end
