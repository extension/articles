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

     @calendar_date = get_calendar_date
     @calendar_events = Page.recent_content({:datatypes => ['Event'], :within_days => 5, :calendar_date => @calendar_date, :limit => 6, :order => 'event_start ASC'})
     @recent_content = Page.recent_content({:datatypes => ['Article','Faq','News'], :limit => 10})
   end
   
  def category_tag
      
    if(!@community.nil?)
      return redirect_to site_index_url(:content_tag => content_tag_url_display_name(params[:content_tag])), :status=>301
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
    
    @calendar_date = get_calendar_date
    
    if(@content_tag.nil?)
      @news = Page.recent_content({:datatypes => ['News'], :limit => 3})
      @recent_learning_lessons = Page.main_lessons_list({:limit => 3})
      @faqs = Page.recent_content({:datatypes => ['Faq'], :limit => 3})
      @calendar_events = Page.recent_content({:datatypes => ['Event'],:within_days => 3, :calendar_date => @calendar_date})
      @articles = Page.ordered(Page.orderings['Newest to oldest']).limit(3)
    else
      @canonical_link = category_tag_index_url(:content_tag => @content_tag.url_display_name)      
      @news = Page.recent_content({:datatypes => ['News'], :content_tag => @content_tag, :limit => 3})
      @recent_learning_lessons = Page.main_lessons_list({:content_tag => @content_tag, :limit => 3})
      @faqs = Page.recent_content({:datatypes => ['Faq'], :content_tags => [@content_tag], :limit => 3})
      @calendar_events =  Page.recent_content({:datatypes => ['Event'],:limit => 5, :calendar_date => @calendar_date, :content_tags => [@content_tag], :order => 'event_start ASC'})
      @newsicles = Page.recent_content({:datatypes => ['Article','News'], :content_tags => [@content_tag], :limit => 8}) unless @community
      @recent_newsicles= Page.recent_content({:datatypes => ['Article','News'], :content_tags => [@content_tag], :limit => 3}) unless @in_this_section
    end
        
    return render(:template => 'main/category_landing') 
    
  end
  
  def community_tag
    @published_content = true  # index CoP landing pages
    
    if(@community.nil?)
      return redirect_to category_tag_index_url(:content_tag => content_tag_url_display_name(params[:content_tag])), :status=>301
    elsif(!canonicalized_category?(params[:content_tag]))
      return redirect_to site_index_url(:content_tag => content_tag_url_display_name(params[:content_tag])), :status=>301
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

    @calendar_date = get_calendar_date
    

    @news = Page.recent_content({:datatypes => ['News'], :content_tag => @content_tag, :limit => 3})
    @recent_learning_lessons = Page.main_lessons_list({:content_tag => @content_tag, :limit => 3})
    @faqs = Page.recent_content({:datatypes => ['Faq'], :content_tags => [@content_tag], :limit => 3})
    @calendar_events =  Page.recent_content({:datatypes => ['Event'],:limit => 5, :calendar_date => @calendar_date, :content_tags => [@content_tag], :order => 'event_start ASC'})
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
    set_title("Search results")
    set_titletag("eXtension - Search results")
  end
      
  def about
    @right_column = false
    set_title('About', "Read about our origins and what we have to offer online.")
    set_titletag('About eXtension - Our origins and what we have to offer')
    @article = Page.find_by_title_url("eXtension_About")
    render :partial => "shared/article", :locals => {:article => @article}, :layout => true
  end
  
  def contact_us
    @right_column = false
    set_title('Contact Us', "Your comments and questions are very important to us. Your quality feedback makes a tremendous impact on improving our site.")
    set_titletag('eXtension - Contact Us')
    @article = Page.find_by_title_url("eXtension_Contact_Us")
    @article_class = "contactus"
    render :partial => "shared/article", :locals => {:article => @article}, :layout => true
  end 

  def privacy
    @right_column = false
    set_title('Privacy Policy', "We have developed this privacy statement in order to demonstrate our commitment to safeguarding the privacy of those who use the eXtension web site.")
    set_titletag('eXtension - Privacy Policy')
    @article = Page.find_by_title_url("eXtension_Privacy_Policy")
    render :partial => "shared/article", :locals => {:article => @article}, :layout => true
  end
  
  def termsofuse
    @right_column = false
    set_title('Terms of Use', "Please read terms of use before using this site.")
    set_titletag('eXtension - Terms of Use')
    @article = Page.find_by_title_url("eXtension_Terms_of_Use")
    render :partial => "shared/article", :locals => {:article => @article}, :layout => true
  end
  
  def disclaimer
    @right_column = false
    set_title('Legal Disclaimer', "Please read the disclaimer before using this site.")
    set_titletag('eXtension - Legal Disclaimer')
    @article = Page.find_by_title_url("eXtension_Disclaimer")
    render :partial => "shared/article", :locals => {:article => @article}, :layout => true
  end

  def partners
    @right_column = false
    set_title('Partners', "Without our partners, eXtension would not be possible.")
    set_titletag('eXtension - Partners')
    @article = Page.find_by_title_url("eXtension_Partners")
    render :partial => "shared/article", :locals => {:article => @article}, :layout => true
  end

  def communities
    @right_column = false
    set_title('Resource Areas', ' eXtension content is organized around resource areas. See which areas might make a connection with you.')
    set_titletag('eXtension - Resource Areas')
    @communities = Community.launched.ordered_by_topic
    @article = Page.find_by_title_url("eXtension_Resource_Areas")
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
  
  def get_calendar_date
    if params[:year] && params[:month] && params[:date]
      date = Date.civil(params[:year].to_i, params[:month].to_i, params[:date].to_i)
    elsif params[:year] && params[:month]
      date = Date.civil(params[:year].to_i, params[:month].to_i, 1)
    else
      date = Time.now.to_date
    end
    
    return date
  end

end
