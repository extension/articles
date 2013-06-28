# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class MainController < ApplicationController
  before_filter :set_content_tag_and_community_and_topic

  layout 'frontporch'
  
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
     
     # articles tagged 'front page' in Create will be eligible for front page display. the one with the latest source updated timestamp will win.
     # in the case that one does not exist, it will fall back to the about page.
     @featured_article = Page.articles.tagged_with_content_tag('front page').ordered.first
     if @featured_article.blank?
       @featured_article = Page.find(:first, :conditions => {:id => SpecialPage.find_by_path('about').page_id})
     end
     
     # articles tagged with both 'front page' and 'bio in Create will be eligible for the front page bio display. the one with the latest source updated timestamp will win.
     # in the case that one does not exist, the bio area will just collapse
     @featured_bio = Page.articles.tagged_with_all_content_tags(['front page', 'bio']).ordered.first
     
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
  
  def about_community
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
    
    @ask_question_widget_url = "https://ask.extension.org/widgets/answered.js?tags=#{@content_tag.name}"
    @learn_event_widget_url = "https://learn.extension.org/widgets/upcoming.js?tags=#{@content_tag.name}"
    
    set_title(@community.public_name,@community.public_description)
    set_titletag("#{@community.public_name} - eXtension")
    @canonical_link = site_index_url(:content_tag => @content_tag.url_display_name)      
    community_content_tag_names = @community.content_tag_names
    @sponsors = Sponsor.tagged_with_any_content_tags(community_content_tag_names).prioritized
    @in_this_section = Page.contents_for_content_tag({:content_tag => @content_tag})
    @about_this_community_section = Page.homage_for_content_tag({:content_tag => @content_tag})
    
    @community_highlights = Page.main_feature_list({:content_tag => @content_tag, :limit => 8})
    flash.now[:googleanalytics] = "/" + @content_tag.name.gsub(' ','_')
    flash.now[:googleanalyticsresourcearea] = @content_tag.name.gsub(' ','_')
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
    
    @ask_question_widget_url = "https://ask.extension.org/widgets/answered?tags=#{@content_tag.name}"
    @learn_event_widget_url = "https://learn.extension.org/widgets/upcoming?tags=#{@content_tag.name}"
    
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
    @featured_bio = Page.articles.tagged_with_all_content_tags(['bio', @content_tag.name]).ordered.first

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
  
  def blog
    @page_title_text = "Blog"
    @pages = Page.diverse_feature_list().paginate(:page => params[:page], :per_page => 10)
    render :template => "/pages/list"
  end
  
  def communities
    @page_title_text = "Our Resources"
    @canonical_link = main_communities_url
    @special_page = SpecialPage.find_by_path('communities')
    @pages = Page.diverse_feature_list().paginate(:page => params[:page], :per_page => 10)
    render :template => "/pages/list"
    # @right_column = false
    # @published_content = true
    # @page = @special_page.page
    # set_title(@special_page.main_heading, @special_page.sub_heading)
    # @communities = PublishingCommunity.launched.ordered_by_topic
    # set_titletag(@special_page.titletag)
    # @pages = pagelist_scope.paginate(:page => params[:page], :per_page => 100)
    # @featured_articles = Page.articles.tagged_with_content_tag('front page').ordered.first
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
    render(:template => "/pages/show")
  end

    
  def show_institution_list
    if params[:zip_or_state]
      if params[:zip_or_state].to_i > 0
        state = to_state(params[:zip_or_state].to_i)
      else
        state = params[:zip_or_state].upcase
      end
      if(!(location = Location.find_by_abbreviation(state)))
        respond_to do |format|
          format.js {render :template => 'main/show_no_institution'}
        end
      else
        branding_institutions_for_location = location.branding_institutions
        if(!branding_institutions_for_location.blank?)
          if(branding_institutions_for_location.length == 1)
            @personal[:institution] = branding_institutions_for_location[0]
            @personal[:location] = location
            session[:location_and_county] = {:location_id => location.id}
            session[:branding_institution_id] = @personal[:institution].id.to_s
            session[:multistate] = nil
            respond_to do |format|
              format.js {render :template => 'main/show_institution'}
            end
          else
            @branding_institutions_for_location = branding_institutions_for_location
            respond_to do |format|
              format.js {render :template => 'main/show_multistate'}
            end
          end
        else
          respond_to do |format|
            format.js {render :template => 'main/show_no_institution'}
          end
        end
      end
    end
  end
  
  def set_institution
    if(institution = BrandingInstitution.find_by_id(params[:institution_id]))
      session[:branding_institution_id] = institution.id
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
