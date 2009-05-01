# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class ReportsController < ApplicationController
  
  def index    
    set_title("Reports")
    set_titletag("Reports - eXtension")
    @right_column = false

    #may want to have a breakdown here between FAQs and Articles
    (@allavg, @allN, @allstdev) = Community.get_overall_ratings_average
    (@faqsavg, @faqsN, @faqsstdev) = Community.get_faqs_ratings_average
    (@artsavg, @artsN, @artsstdev) = Community.get_articles_ratings_average
    
  end
  
  def overall_ratings_by_category
    set_title("Overall Ratings by Category")
    set_titletag("Overall Ratings by Category - eXtension")
    @right_column = false
    @avgs = Community.get_average_overall_ratings
    render :template => 'reports/ratings_by_category'
  end

 
  def faq_ratings_by_category
    set_title("FAQ Ratings by Category")
    set_titletag("FAQ Ratings by Category - eXtension")
    @right_column = false
    @avgs = Community.get_average_faq_ratings
    render :template=> 'reports/ratings_by_category'
  end
  
  def wiki_ratings_by_category
    set_title("Article Ratings by Category")
    set_titletag("Article Ratings by Category - eXtension")
    @right_column = false
    @avgs = Community.get_average_wiki_ratings
    render :template => 'reports/ratings_by_category'
  end
  
  
end
