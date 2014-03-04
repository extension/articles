Darmok::Application.routes.draw do
  root :to => 'main#index'

  # auth
  match '/logout', to:'auth#end', :as => 'logout'
  match '/auth/:provider/callback', to: 'auth#success'
  match '/auth/failure', to: 'auth#failure'

      
  ### Widget Stuff ###
  # redirects
  namespace :widgets do
    match '/generate_new_widget', to: "content#generate_new_widget", :as => 'generate_new_widget'
    match '/content', to: "content#index", :as => 'content'
    match '/content/show', to: "content#show", :as => 'content_show'
    match '/', to: "home#index", :as => 'home'
  end
  

  ## Debug ##
  match 'debug/location', to:'debug#location', :as => 'debuglocation'

#   #################################################################
#   ### pubsite routes ###
#   map.redirect 'main', :controller => 'main', :action => 'index', :permanent => true
#   map.connect 'feeds', :controller => 'feeds'
    

#   ### pubsite redirect routes
#   map.redirect 'wiki/*title', :controller => 'articles', :action => 'page', :permanent => true
#   map.redirect 'news', :controller => 'pages', :action => 'news', :content_tag => 'all', :permanent => true  
#   map.redirect 'faqs', :controller => 'pages', :action => 'faqs', :content_tag => 'all', :permanent => true
#   map.redirect 'articles', :controller => 'pages', :action => 'articles', :content_tag => 'all', :permanent => true
  
  ### admin routes
  namespace :admin do
    resources :sponsors, :collection => {:update_positions => :post}
    resources :logos
  end

  match 'feeds', to: "feeds#index"
  match 'feeds/content/:tags', to: "feeds#content", as: 'content_feed'
  match 'feeds/community/-/:tags', to: "feeds#community"
  match 'feeds/articles', to: "feeds#content", :content_types => 'articles'
  match 'feeds/faqs', to: "feeds#content", :content_types => 'faqs'
  match 'feeds/events', to: "feeds#content", :content_types => 'events'
  match 'feeds/all', to: "feeds#content"
  match 'feeds/:action', to: "feeds"


  match 'admin/:action/:id', :controller => 'admin'
  match 'admin/:action', :controller => 'admin'
  match 'admin', to: 'admin#index', :as => 'admin_index'
  match 'admin/edit_institution_logo', to: 'admin#edit_institution_logo', :as => 'admin_edit_institutional_logo'
  
  match 'notice/admin_required', to: 'notice#admin_required'
  
  ### api routes
  namespace :api do
    match 'data/:action', to: 'data'
  end
  
  ### current routes for specific content
  match 'pages/list', to:'pages#list', :as => 'pagelist'
  match 'pages/:id/print', to:'pages#show', :as => 'print_pageid', :defaults => { :print => 1 }
  match 'pages/:id', to:'pages#show', :as => 'pageid', :constraints => { :id => /\d+/ }
  match 'pages/:id/:title/print', to:'pages#show', :as => 'print_page', :defaults => { :print => 1 }
  match 'pages/:id/:title', to:'pages#show', :as => 'page', :constraints => { :id => /\d+/ }

  ### old routes for specific content
  match 'article/:id/print', to:'pages#redirect_article', :defaults => { :print => 1 }, :constraints => { :id => /\d+/ }
  match 'article/:id', to:'pages#redirect_article', :constraints => { :id => /\d+/ }
  match 'events/:id/print', to:'pages#redirect_event', :defaults => { :print => 1 }, :constraints => { :id => /\d+/ }
  match 'events/:id', to:'pages#redirect_event', :constraints => { :id => /\d+/ }  
  match 'faq/:id/print', to:'pages#redirect_faq', :defaults => { :print => 1 }, :constraints => { :id => /\d+/ }
  match 'faq/:id', to:'pages#redirect_faq', :constraints => { :id => /\d+/ }
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
  match ':id', to:'pages#show', :constraints => { :id => /\d+/ }, :as => 'short_pageid'

  match 'main/search', to:'main#search', :as => 'site_search'
  match 'main/blog', to:'main#blog', :as => 'main_blog'
  match 'main/communities', to:'main#communities', :as => 'main_communities'
  match 'main/set_institution', to:'main#set_institution', :as => 'set_institution'
  match 'main/show_institution_list', to:'main#show_institution_list', :via => [:post], :as => 'show_institution_list'
  match 'main/:path', to:'main#special', :as => 'main_special'
  match ':content_tag', to:'main#community_tag', :as => 'site_index'
  match ':content_tag/about', to:'main#about_community', :as => 'about_community'
  
  # this must be last
  # match '*path', to:'application#do_404', :constraints => { :path => /.*/ }

end
