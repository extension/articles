# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class MainController < ApplicationController
  protect_from_forgery :except => :find_institution
  before_filter :set_content_tag_and_community_and_topic

  def index
     set_title('Objective. Research-based. Credible. Information and tools you can use every day to improve your life.')
     set_titletag('eXtension - Objective. Research-based. Credible.')
        
     @sponsors = Sponsor.prioritized
     
     @in_the_news = Article.main_news_list({:limit => 4})
     @community_highlights = Article.main_feature_list({:limit => 8})
     @latest_activities = Article.main_recent_list({:limit => 8})
     @latest_faq = Faq.ordered.first
     @latest_article = @latest_activities[0]
     @second_latest = @latest_activities[1]
     
     date_conditions = ['start >= ? AND start < ?', get_calendar_date, get_calendar_date+5]
     @calendar_events = Event.find(:all, :conditions => date_conditions, :order => 'date ASC')
     learning_lessons = Article.main_lessons_list({:limit => 3})  
     @latest_learning_lesson =  learning_lessons[0] if learning_lessons
  end

  def content_tag
    if(!@community.nil?)
      set_title(@community.public_name,@community.public_description)
      set_titletag("#{@community.public_name} - eXtension")
      # TODO: write a helper method to get the content tags
      @community_content_tags = @community.tags
      @sponsors = Sponsor.tagged_with_any_content_tags(@community_content_tags.map(&:name)).prioritized
      
      @homage = Article.homage_for_content_tag({:content_tag => @content_tag})
      @in_this_section = Article.contents_for_content_tag({:content_tag => @content_tag})
      @community_highlights = Article.main_feature_list({:content_tag => @content_tag, :limit => 8})
      @youth = true if @topic and @topic.name == 'Youth'
      flash.now[:googleanalytics] = "/" + @content_tag.name.gsub(' ','_')
    elsif(!@content_tag.nil?)
      set_title("Content tagged with:", @content_tag.name.titleize)
      set_titletag("Content tagged with '#{@content_tag.name}'  - eXtension")
      @youth = true if @content_tag.name == 'youth'
    else
      set_title("All Content")
      set_titletag("All Content - eXtension")  
    end
    
    if(@content_tag.nil?)
      @news = Article.main_news_list({:limit => 3})
      @recent_learning_lessons = Article.main_lessons_list({:limit => 3})
      @faqs = Faq.limit(3).ordered
      @calendar_events = Event.ordered.within(3, get_calendar_date)
      @articles = Article.ordered(Article.orderings['Newest to oldest']).limit(3)
    else
      @news = Article.main_news_list({:content_tag => @content_tag, :limit => 3})
      @recent_learning_lessons = Article.main_lessons_list({:content_tag => @content_tag, :limit => 3})
      @faqs = Faq.tagged_with_content_tag(@content_tag.name).ordered.limit(3)
      @calendar_events =  Event.tagged_with_content_tag(@content_tag.name).ordered.limit(5).after(get_calendar_date)
      @articles = Article.main_feature_list({:content_tag => @content_tag, :limit => 8}) unless @community
      @recent_articles = Article.main_feature_list({:content_tag => @content_tag, :limit => 3}) unless @in_this_section
    end
  end
  
  def search
    set_title("Search results")
    set_titletag("eXtension - Search results")
  end
  
  def version
    set_title('App Information')
    set_titletag("App Information - eXtension")
    @deploy = Hash.new
    @deploy['version'] = AppVersion.version
    fname = 'REVISION'
    if File.exists?(fname)
      stat = File.stat(fname)
      @deploy['date'] = stat.ctime
      @deploy['revision'] = File.read(fname)
      @deploy['userid'] = stat.uid
      userinfo = Etc.getpwuid(stat.uid)
      @deploy['username'] = userinfo.name
    end
    render(:layout => false)
  end
    
  def about
    set_title('About', "Read about our origins and what we have to offer online.")
    set_titletag('About eXtension - Our origins and what we have to offer')
    @article = Article.find_by_title_url("eXtension_About")
    render :partial => "shared/article", :locals => {:article => @article}, :layout => true
  end
  
  def contact_us
    set_title('Contact Us', "Your comments and questions are very important to us. Your quality feedback makes a tremendous impact on improving our site.")
    set_titletag('eXtension - Contact Us')
    @article = Article.find_by_title_url("eXtension_Contact_Us")
    @article_class = "contactus"
    render :partial => "shared/article", :locals => {:article => @article}, :layout => true
  end 

  def privacy
    set_title('Privacy Policy', "We have developed this privacy statement in order to demonstrate our commitment to safeguarding the privacy of those who use the eXtension web site.")
    set_titletag('eXtension - Privacy Policy')
    @article = Article.find_by_title_url("eXtension_Privacy_Policy")
    render :partial => "shared/article", :locals => {:article => @article}, :layout => true
  end
  
  def termsofuse
    set_title('Terms of Use', "Please read terms of use before using this site.")
    set_titletag('eXtension - Terms of Use')
    @article = Article.find_by_title_url("eXtension_Terms_of_Use")
    render :partial => "shared/article", :locals => {:article => @article}, :layout => true
  end
  
  def disclaimer
    set_title('Legal Disclaimer', "Please read the disclaimer before using this site.")
    set_titletag('eXtension - Legal Disclaimer')
    @article = Article.find_by_title_url("eXtension_Disclaimer")
    render :partial => "shared/article", :locals => {:article => @article}, :layout => true
  end

  def partners
    set_title('Partners', "Without our partners, eXtension would not be possible.")
    set_titletag('eXtension - Partners')
    @article = Article.find_by_title_url("eXtension_Partners")
    render :partial => "shared/article", :locals => {:article => @article}, :layout => true
  end

  def communities
    set_title('Resource Areas', ' eXtension content is organized around resource areas. See which areas might make a connection with you.')
    set_titletag('eXtension - Resource Areas')
    @communities = Community.launched.ordered_by_topic
    @article = Article.find_by_title_url("eXtension_Resource_Areas")
  end

  def sponsors
    set_title('Our Sponsors')
    set_titletag('eXtension - Our Sponsors')
    @article = Article.find_by_title_url("eXtension_Sponsors")
    render :partial => "shared/article", :locals => {:article => @article}, :layout => true
  end
    
  def show_institution_list
    if params[:zip_or_state]
      if params[:zip_or_state].to_i > 0
        state = to_state(params[:zip_or_state].to_i)
      else
        state = params[:zip_or_state].upcase
      end
      insts = Institution.find(:all, :conditions => ["entrytype = #{Institution::LANDGRANT} and location_abbreviation = ?", state])
      if insts and insts.length > 0
        if insts[0].shared_logo or insts.length == 1
          render :partial => "shared/institution_selected", :locals => {:state => state}, :layout => false
        else
          render :partial => "shared/institution_select", :locals => {:institutions => insts}, :layout => false
        end
        return
      end
    end
    render :nothing => true
  end
  
  def set_institution
    session[:institution_id] = params[:institution_id]
    session[:multistate] = nil
    request.env["HTTP_REFERER"] ? (redirect_to :back) : (redirect_to home_url) 
  end
    
  def find_institution
    @personal[:location] = Location.find_by_abbreviation(params[:state])
    if(@personal[:location] && @personal[:location].institutions.public_list.length > 0)
      if @personal[:location].institutions.public_list[0].shared_logo or
         @personal[:location].institutions.public_list.length == 1
        @personal[:state] = params[:state]
        @personal[:institution] = @personal[:location].institutions.public_list[0]
        session[:institution_id] = @personal[:institution].id.to_s
        session[:multistate] = nil
      else
        session[:multistate] = params[:state]
      end
    else
      return render(:partial => "shared/no_institution", :layout => false)
    end
    render :partial => "shared/logo", :locals => {:person => @personal}, :layout => false
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
