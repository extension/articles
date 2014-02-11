# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
# 
#  see LICENSE file

class MainController < ApplicationController
  before_filter :set_content_tag_and_community_and_topic

  layout 'frontporch'
  
  def index
    @published_content = true  # index the main page
    sponsorlist = Sponsor.all
    @sponsors = Hash.new
    Sponsor::SPONSORSHIP_LEVELS.each{ |level| @sponsors[level] = Array.new}
    sponsorlist.each{ |sponsor| @sponsors[sponsor.level] << sponsor if sponsor.level}
     
    # articles tagged 'front page' in Create will be eligible for front page display. the one with the latest source updated timestamp will win.
    # in the case that one does not exist, it will fall back to the about page.
    @featured_articles = Page.articles.tagged_with_all_content_tags(['front page', 'feature']).ordered.limit(1)
    if @featured_articles.blank?
      @featured_articles << Page.find(:first, :conditions => {:id => SpecialPage.find_by_path('about').page_id})
    end
     
    # Articles tagged with 'front page' and 'bio in Create will be eligible for the front page bio display.
    # The one with the latest source updated timestamp will win.
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
    
    
    if(!@content_tag.nil? and !canonicalized_category?(params[:content_tag]))
      return redirect_to(:action => params[:action],:content_tag => content_tag_url_display_name(params[:content_tag]), :status=>301)
    end
    
    @show_selector = true
    @list_content = true # don't index this page
    order = (params[:order].blank?) ? "source_updated_at DESC" : params[:order]
    # validate order
    return do_404 unless Page.orderings.has_value?(order)
    
    if(!@content_tag.nil?)
      set_title("Content tagged \"#{@content_tag.name}\"")
      @pages = Page.tagged_with_content_tag(@content_tag.name).ordered(order).paginate(:page => params[:page])
    else
      set_title("Recent Content")
      @pages = Page.ordered(order).paginate(:page => params[:page])
    end
    render(:template => 'pages/list')
    
  end
  
  def about_community

    if(@community.nil?)
      # check for CategoryTagRedirect
      if(redirect = CategoryTagRedirect.where("term = ?",params[:content_tag].downcase).first)
        return redirect_to(redirect.target_url, :status=>301)
      else
        return redirect_to category_tag_index_url(:content_tag => content_tag_url_display_name(params[:content_tag])), :status=>301
      end
    elsif(@page = Page.homage_for_content_tag({:content_tag => @content_tag}))
      return redirect_to(page_url(:id => @page.id, :title => @page.url_title),:status => :moved_permanently)
    else
      return redirect_to(site_index_url(:content_tag => @content_tag.url_display_name),:status => :moved_permanently)
    end

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
    
    @donation_block = false
    if(@community and @community.show_donation.present?)
      @donation_block = true
    end
    
    if(@community and @community.aae_group_id.present?)
      @ask_two_point_oh_form = "#{@community.ask_an_expert_group_url}/ask"
    else
      @ask_two_point_oh_form = AppConfig.configtable['ask_two_point_oh_form']
    end
    
    @in_this_section = Page.contents_for_content_tag({:content_tag => @content_tag})
    @ask_question_widget_url = "https://ask.extension.org/widgets/answered.js?tags=#{@content_tag.name}"
    @learn_event_widget_url = "https://learn.extension.org/widgets/upcoming.js?tags=#{@content_tag.name}"
    
    set_title(@community.public_name)
    @canonical_link = site_index_url(:content_tag => @content_tag.url_display_name)      
    community_content_tag_names = @community.content_tag_names
    @sponsors = Sponsor.tagged_with_any_content_tags(community_content_tag_names).prioritized
    @in_this_section = Page.contents_for_content_tag({:content_tag => @content_tag})
    @community_highlights = Page.main_feature_list({:content_tag => @content_tag, :limit => 8})
    flash.now[:googleanalytics] = "/" + @content_tag.name.gsub(' ','_')
    flash.now[:googleanalyticsresourcearea] = @content_tag.name.gsub(' ','_')
    @featured_bio = Page.articles.tagged_with_all_content_tags(['bio', @content_tag.name]).offset(rand(Page.articles.tagged_with_all_content_tags(['bio', @content_tag.name]).length)).first

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
    set_title("eXtension - Search results")
  end
  
  def blog
    @page_title = "Recently Featured"
    order = "source_updated_at DESC"
    @pages = Page.articles.tagged_with_all_content_tags(['front page', 'feature']).ordered(order).paginate(:page => params[:page], :per_page => 10)
    if @pages.blank?
      @pages << Page.find(:first, :conditions => {:id => SpecialPage.find_by_path('about').page_id})
    end
    
    render :template => "/pages/list"
  end
  
  def communities
    @page_title = "Our Resources"
    @canonical_link = main_communities_url
    @special_page = SpecialPage.find_by_path('communities')
    @pages = Page.diverse_feature_list().paginate(:page => params[:page], :per_page => 10)
    render :template => "/pages/list"
  end
  
  def special
    path = params[:path]
    if(!path or !@special_page = SpecialPage.find_by_path(path))
      return do_404
    end

    @published_content = true
    @canonical_link = main_special_url(:path => @special_page.path)
    @page = @special_page.page
    @learn_event_widget_url = "https://learn.extension.org/widgets/front_porch.js"
    set_title(@special_page.main_heading)
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
