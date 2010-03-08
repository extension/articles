# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class FaqController < ApplicationController
  before_filter :set_content_tag_and_community_and_topic
  
  layout 'pubsite'
  
  def index
    # validate ordering
    return do_404 unless Faq.orderings.has_value?(params[:order])
    set_title('Answered Questions from Our Experts', "Frequently asked questions from our resource area experts.")
    if(!@content_tag.nil?)
      set_titletag("Answered Questions from Our Experts - #{@content_tag.name} - eXtension")      
      @faqs = Faq.tagged_with_content_tag(@content_tag.name).ordered(params[:order]).paginate(:page => params[:page])
    else
      set_titletag('Answered Questions from Our Experts - all - eXtension')
      @faqs = Faq.ordered(params[:order]).paginate(:page => params[:page])
    end  
    @youth = true if @topic and @topic.name == 'Youth'
    render :partial => 'shared/dataitems', :locals => { :items => @faqs, :klass => Faq }, :layout => true
  end
  
  def detail
    @right_sidebar_to_display = 'faq_navigation'
    @faq = Faq.find_by_id(params[:id])
    if @faq
      set_title("#{@faq.question}", "Frequently asked questions from our resource area experts.")
      set_titletag("#{@faq.question} - eXtension")
      @published_content = true
    else 
      @missing = "FAQ #{params[:id]}"
      do_404
      return
    end

    # get the tags on this faq that correspond to community content tags
    faq_content_tags = @faq.tags.content_tags
    if(!faq_content_tags.blank?)
      # is this article tagged with youth?
      @youth = true if faq_content_tags.map(&:name).include?('youth')
      
      # get the tags on this article that are content tags on communities
      @community_content_tags = (Tag.community_content_tags & faq_content_tags)
      
      @faq_public_tags = faq_content_tags
    
      if(!@community_content_tags.blank?)
        @sponsors = Sponsor.tagged_with_any_content_tags(@community_content_tags.map(&:name)).prioritized
        # loop through the list, and see if one of these matches my @community already
        # if so, use that, else, just use the first in the list
        use_content_tag = @community_content_tags.rand
        @community_content_tags.each do |community_content_tag|
          if(community_content_tag.content_community == @community)
            use_content_tag = community_content_tag
          end
        end
      
        @community = use_content_tag.content_community
        @homage = Article.homage_for_content_tag({:content_tag => use_content_tag}) if @community
        @in_this_section = Article.contents_for_content_tag({:content_tag => use_content_tag}) if @community
        @youth = true if @community and @community.topic and @community.topic.name == 'Youth'
      end
    end    

    flash.now[:googleanalytics] = request.request_uri + "?" + @community_content_tags.collect{|tag| tag.content_community }.uniq.compact.collect { |community| community.primary_content_tag_name }.join('+').gsub(' ','_') if @community_content_tags and @community_content_tags.length > 0
  end
end
