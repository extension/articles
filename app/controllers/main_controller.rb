# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class MainController < DataController
  skip_before_filter :disable_link_prefetching, :get_tag, :only => :find_institution

  def index
     set_title('Objective. Research-based. Credible. Information and tools you can use every day to improve your life.')
     set_titletag('eXtension - Objective. Research-based. Credible.')
     
     # TODO These need to go
     get_month
     get_date
     
     @sponsors = Advertisement.prioritized_for_tag(Tag.find_by_name('all'))
     
     @in_the_news = Article.tagged_with_content_tags('news').ordered.limit(4)
     
     @community_highlights = Article.tagged_with_content_tags('feature').ordered.limit(8)
     
     @latest_activities = Article.find(:all, :order => 'wiki_updated_at DESC', :limit => 4)
     @latest_faq = Faq.ordered.first

     @latest_article = @latest_activities[0]
     @second_latest = @latest_activities[1]
     
     date_conditions = ['start >= ? AND start < ?', @date, @date+5]
     @calendar_events = Event.find(:all, :conditions => date_conditions, :order => 'date ASC')

     @latest_learning_lesson = Article.tagged_with_content_tags('learning lessons').ordered.first     
  end

  def category
    if !@category
      render(:file => 'public/404.html', :layout => false) 
      return
    end

    get_month
    get_date
    
    if @community
      set_title(@community.name,@community.public_description)
      set_titletag("#{@community.public_name} - eXtension")
      # TODO: write a helper method to get the content tags
      @community_tags = @community.tags
      adtag = @community_tags[0] if @community_tags and @community_tags.length > 0
      @sponsors = Advertisement.prioritized_for_tag(adtag) if adtag
      
      @homage = Article.tagged_with_content_tags(['homage', params[:category]]).ordered.first
      @in_this_section = Article.tagged_with_content_tags(['contents', params[:category]]).ordered.first
      @community_highlights = Article.tagged_with_content_tags(['feature', params[:category]]).
          ordered.limit(8)
      @youth = true if @topic and @topic.name == 'Youth'
          
    else
      set_title("Content tagged with:", @category.name.titleize)
      set_titletag("Content tagged with '#{@category.name}'  - eXtension")
      @youth = true if @category.name == 'youth'
    end
    
    if @category.name == 'all'
      
      @news = Article.tagged_with_content_tags('news').ordered.limit(3)
      @popular_learning_lessons = Article.tagged_with_content_tags('learning lessons').ordered(Article.orderings['Most Useful']).limit(3)
      @faqs = Faq.limit(3).ordered
      @calendar_events = Event.ordered.within(3, @date)
      @articles = Article.ordered(Article.orderings['Most Useful']).limit(3)
      
    else
      
      @news = Article.tagged_with_content_tags(['news', params[:category]]).ordered.limit(3)
      @popular_learning_lessons = 
        Article.tagged_with_content_tags(['learning lessons', params[:category]]).
          ordered(Article.orderings['Most Useful']).limit(3)
          
      @faqs = Faq.tagged_with_content_tags(@category.name).ordered.limit(3)
      @calendar_events =  Event.tagged_with_content_tags(@category.name).ordered.limit(5).after(@date)
    
      @articles = Article.tagged_with_content_tags(params[:category]).
          ordered(Article.orderings['Most Useful']).limit(8) unless @community
        
      @recent_articles = Article.tagged_with_content_tags(params[:category]).
              ordered.limit(3) unless @in_this_section
      
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
  
  def bork
    MrBork.find(:all, :include => :all_borken_ness)
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
    @communities = Community.find_all_visible_sorted
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
      insts = Institution.find_all_by_state(state)
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
    cookies[:institution_id] = {:value => params[:institution_id], :expires => 1.month.from_now}
    session[:multistate] = nil
    request.env["HTTP_REFERER"] ? (redirect_to :back) : (redirect_to home_url) 
  end
    
  def find_institution
    @personal[:location] = Location.find_by_abbreviation(params[:state])
    if(@personal[:location] && @personal[:location].institutions.length > 0)
      if @personal[:location].institutions[0].shared_logo or
         @personal[:location].institutions.length == 1
        @personal[:state] = params[:state]
        @personal[:institution] = @personal[:location].institutions[0]
        cookies[:institution_id] = {:value => @personal[:institution].id.to_s, :expires => 1.month.from_now}
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
  
end
