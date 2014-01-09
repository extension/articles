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
  

  ## Debug ##
  match 'debug/location', to:'debug#location', :as => 'debuglocation'

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
  
  ### pubsite admin routes
  namespace :admin do
    resources :sponsors, :collection => {:update_positions => :post}
    resources :logos
  end

  match 'admin/:action/:id', :controller => 'admin'
  match 'admin/:action', :controller => 'admin'
  
  ### connect up "data" to the api/data controller
  match 'data/:action', to:'api#data'
  
  ### current routes for specific content
  match 'pages/list', to:'pages#list', :as => 'pagelist'
  match 'pages/:id/print', to:'pages#show', :as => 'print_pageid', :defaults => { :print => 1 }
  match 'pages/:id', to:'pages#show', :as => 'pageid', :requirements => { :id => /\d+/ }
  match 'pages/:id/:title/print', to:'pages#show', :as => 'print_page', :defaults => { :print => 1 }
  match 'pages/:id/:title', to:'pages#show', :as => 'page'

  ### old routes for specific content
  match 'article/:id/print', to:'pages#redirect_article', :defaults => { :print => 1 }, :requirements => { :id => /\d+/ }
  match 'article/:id', to:'pages#redirect_article', :requirements => { :id => /\d+/ }
  match 'events/:id/print', to:'pages#redirect_event', :defaults => { :print => 1 }, :requirements => { :id => /\d+/ }
  match 'events/:id', to:'pages#redirect_event', :requirements => { :id => /\d+/ }  
  match 'faq/:id/print', to:'pages#redirect_faq', :defaults => { :print => 1 }, :requirements => { :id => /\d+/ }
  match 'faq/:id', to:'pages#redirect_faq', :requirements => { :id => /\d+/ }
  match 'pages/*title', to:'pages#redirect_article'

  ### more named routes
  match 'logo/:file', to:'logo#display', :as => 'logo'
  match 'reports', to:'reports#index', :as => 'reports'
  match 'category/:content_tag', to:'main#category_tag', :as => 'category_tag_index'

  # preview
  match 'preview/page/:source/:source_id', to:'preview#showpage', :as => 'preview_page'
  match 'preview/:content_tag', to:'preview#content_tag', :as => 'preview_tag'
  match 'preview/showcategory/:categorystring', to:'preview#showcategory', :as => 'preview_category'
  match 'preview', to:'preview#index', :as => 'preview_home'

  # pageinfo
  match 'pageinfo/pagelinklist/:content_tag', to:'pageinfo#pagelinklist', :as => 'pageinfo_pagelinklist'
  match 'pageinfo/pagelist/:content_tag', to:'pageinfo#pagelist', :as => 'pageinfo_pagelist'
  match 'pageinfo/source/:source_name/:source_id', to:'pageinfo#find_by_source', :as => 'pageinfo_source'
  match 'pageinfo/source', to:'pageinfo#find_by_source', :as => 'pageinfo_findsource'
  match 'pageinfo/:id', to:'pageinfo#show', :as => 'pageinfo_page'

  # legacy routes to 410
  match ':content_tag/events/:year', to:'main#legacy_events_redirect'
  match ':content_tag/events/:year/:month', to:'main#legacy_events_redirect'
  match ':content_tag/events/:year/:month/:event_stat', to:'main#legacy_events_redirect'
  
  ### pubsite content_tag routes - should pretty much catch *everything* else right now
  match ':content_tag/news', to:'pages#news', :as => 'site_news'
  match ':content_tag/faqs', to:'pages#faqs', :as => 'site_faqs'
  match ':content_tag/articles', to:'pages#articles', :as => 'site_articles'
  match ':content_tag/events', to:'pages#events', :as => 'site_events'
  match ':content_tag/learning_lessons', to:'pages#learning_lessons', :as => 'site_learning_lessons'

  ### short pageid
  match ':id', to:'pages#show',  :requirements => { :id => /\d+/ }, :as => 'short_pageid'

  match 'main/search', to:'main#search', :as => 'site_search'
  match 'main/blog', to:'main#blog', :as => 'main_blog'
  match 'main/communities', to:'main#communities', :as => 'main_communities'
  match 'main/set_institution', to:'main#set_institution', :as => 'set_institution'
  match 'main/show_institution_list', to:'main#show_institution_list', :via => [:post], :as => 'show_institution_list'
  match 'main/:path', to:'main#special', :as => 'main_special'
  match ':content_tag', to:'main#community_tag', :as => 'site_index'
  match ':content_tag/about', to:'main#about_community', :as => 'about_community'

  # this must be last
  match '*path', to:'application#do_404', :requirements => { :path => /.*/ }

end
