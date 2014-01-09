Darmok::Application.routes.draw do
  root :to => 'main#index'

  # auth
  match '/logout', to:'auth#end', :as => 'logout'
  match '/auth/:provider/callback', to: 'auth#success'

      
  ### Widget Stuff ###
  # redirects
  namespace :widgets do
    match '/generate_new_widget', to: "content#generate_new_widget", :as => 'generate_new_widget'
    match '/content', to: "content#index", :as => 'content'
    match '/', to: "home#index", :as => 'home'
  end
  
end

#   ## Debug ##
#   map.debuglocation 'debug/location', :controller => 'debug', :action => 'location'

#   #################################################################
#   ### pubsite routes ###
#   map.redirect 'main', :controller => 'main', :action => 'index', :permanent => true
#   map.connect 'feeds', :controller => 'feeds'
    
#   map.redirect 'feeds/articles', :controller => 'feeds', :action => 'content', :content_types => 'articles', :permanent => true  
#   map.redirect 'feeds/faqs', :controller => 'feeds', :action => 'content', :content_types => 'faqs', :permanent => true  
#   map.redirect 'feeds/events', :controller => 'feeds', :action => 'content', :content_types => 'events', :permanent => true  
#   map.redirect 'feeds/all', :controller => 'feeds', :action => 'content', :permanent => true  

#   map.connect 'feeds/community/-/:tags', :controller => 'feeds', :action => 'community'
#   map.content_feed 'feeds/content/:tags', :controller => 'feeds', :action => 'content'
#   map.connect 'feeds/:action', :controller => 'feeds'
  
#   ### pubsite redirect routes
#   map.redirect 'wiki/*title', :controller => 'articles', :action => 'page', :permanent => true
#   map.redirect 'news', :controller => 'pages', :action => 'news', :content_tag => 'all', :permanent => true  
#   map.redirect 'faqs', :controller => 'pages', :action => 'faqs', :content_tag => 'all', :permanent => true
#   map.redirect 'articles', :controller => 'pages', :action => 'articles', :content_tag => 'all', :permanent => true
  
#   ### pubsite admin routes
#   map.namespace :admin do |admin|
#     admin.resources :sponsors, :collection => {:update_positions => :post}
#     admin.resources :logos
#   end
  
#   map.connect 'admin/:action/:id', :controller => 'admin'
#   map.connect 'admin/:action', :controller => 'admin'
  
#   ### connect up "data" to the api/data controller
#   map.connect 'data/:action', :controller => 'api/data'
  
#   ### current routes for specific content
#   map.pagelist 'pages/list', :controller => 'pages', :action => 'list'

#   map.print_pageid 'pages/:id/print', :controller => 'pages', :action => 'show', :requirements => { :id => /\d+/ }
#   map.pageid 'pages/:id', :controller => 'pages', :action => 'show', :requirements => { :id => /\d+/ }
#   map.print_page 'pages/:id/:title/print', :controller => 'pages', :action => 'show', :print => 1
#   map.page 'pages/:id/:title', :controller => 'pages', :action => 'show', :requirements => { :id => /\d+/ }

#   ### old routes for specific content
#   map.connect 'article/:id/print', :controller => 'pages', :action => 'redirect_article', :print => 1, :requirements => { :id => /\d+/ }
#   map.connect 'article/:id', :controller => 'pages', :action => 'redirect_article', :requirements => { :id => /\d+/ }
#   map.connect 'events/:id/print', :controller => 'pages', :action => 'redirect_event', :print => 1
#   map.connect 'events/:id', :controller => 'pages', :action => 'redirect_event'
#   map.connect 'faq/:id/print', :controller => 'pages', :action => 'redirect_faq', :print => 1
#   map.connect 'faq/:id', :controller => 'pages', :action => 'redirect_faq'  
#   map.connect 'pages/*title', :controller => 'pages', :action => 'redirect_article'

#   # more named routes
#   map.logo  'logo/:file.:format', :controller => 'logo', :action => :display
#   map.reports 'reports', :controller => :reports
#   map.category_tag_index 'category/:content_tag', :controller => 'main', :action => 'category_tag'
  
#   # wiki compatibility version
#   #map.preview_wikipage 'preview/pages/*title', :controller => 'preview', :action => 'showpage' # note :title is ignored in the method, and the URI is gsub'd because of '?' characters
#   # everyone else
#   map.preview_page 'preview/page/:source/:source_id', :controller => 'preview', :action => 'showpage'
   
#   map.preview_tag 'preview/:content_tag', :controller => 'preview', :action => 'content_tag'
#   map.preview_category 'preview/showcategory/:categorystring', :controller => 'preview', :action => 'showcategory'
#   map.preview_home 'preview', :controller => 'preview', :action => 'index'

#   map.pageinfo_pagelinklist 'pageinfo/pagelinklist/:content_tag', :controller => 'pageinfo', :action => 'pagelinklist'
#   map.pageinfo_pagelist 'pageinfo/pagelist/:content_tag', :controller => 'pageinfo', :action => 'pagelist'
#   map.pageinfo_source 'pageinfo/source/:source_name/:source_id', :controller => 'pageinfo', :action => 'find_by_source'
#   map.pageinfo_findsource  'pageinfo/source', :controller => 'pageinfo', :action => 'find_by_source'
#   map.pageinfo_page 'pageinfo/:id', :controller => 'pageinfo', :action => 'show'

#   # legacy routes to 410
#   map.connect ':content_tag/events/:year', :controller => 'main', :action => 'legacy_events_redirect'
#   map.connect ':content_tag/events/:year/:month', :controller => 'main', :action => 'legacy_events_redirect'
#   map.connect ':content_tag/events/:year/:month/:event_stat', :controller => 'main', :action => 'legacy_events_redirect'
  
  
#   ### pubsite content_tag routes - should pretty much catch *everything* else right now
#   map.site_news ':content_tag/news', :controller => 'pages', :action => 'news'
#   map.site_faqs ':content_tag/faqs', :controller => 'pages', :action => 'faqs'
#   map.site_articles ':content_tag/articles', :controller => 'pages', :action => 'articles'
#   map.site_events ':content_tag/events', :controller => 'pages', :action => 'events'
#   map.site_learning_lessons ':content_tag/learning_lessons', :controller => 'pages', :action => 'learning_lessons'

#   map.short_pageid ':id', :controller => 'pages', :action => 'show',  :requirements => { :id => /\d+/ }

#   map.site_search '/main/search', :controller => 'main', :action => 'search'
#   map.main_blog '/main/blog', :controller => 'main', :action => 'blog'
#   map.main_communities '/main/communities', :controller => 'main', :action => 'communities'
#   map.set_institution '/main/set_institution', :controller => 'main', :action => 'set_institution'
#   map.show_institution_list '/main/show_institution_list', :controller => 'main', :action => 'show_institution_list', :conditions => { :method => :post }
#   map.main_special '/main/:path', :controller => 'main', :action => 'special'
  
#   map.site_index ':content_tag', :controller => 'main', :action => 'community_tag'
#   map.about_community ':content_tag/about', :controller => 'main', :action => 'about_community'
  

#   ### catch?  I'm not sure that these are ever actually touched because of the :content_tag routes above
#   map.connect ':controller', :action => 'index'
#   map.connect ':controller/:action'
#   map.connect ':controller/:action/:id'
#   map.connect ':controller/:action/:id.:format'
  
#   # this must be last
#   map.connect '*path', :controller => 'application', :action => 'do_404', :requirements => { :path => /.*/ }
# end
