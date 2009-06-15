ActionController::Routing::Routes.draw do |map|
  
  map.root :controller => 'main'
  
  map.resources :assets, :path_prefix => '/admin', :except => :show
  map.resources :county_links, :path_prefix => '/admin'
  map.resources :institutions, :path_prefix => '/admin'
  map.resources :feed_locations, :path_prefix => '/admin'
  
  map.asset 'admin/asset/:file', :controller => "assets", :action => "show"
  map.connect 'admin/asset/:file.:format', :controller => "assets", :action => "show"
      
  map.open_id_complete 'openidsession', :controller => "openidsessions", :action => "create", :requirements => { :method => :get }
  map.resource :openidsession
  
  map.home '', :controller => 'main', :action => 'index'
  map.redirect 'news', :controller => 'articles', :action => 'news', :page => '1', :order => 'wiki_updated_at DESC', :category => 'all', :permanent => true
  map.redirect 'faqs', :controller => 'faq', :action => 'index', :page => '1', :order => 'heureka_published_at DESC', :category => 'all', :permanent => true
  map.redirect 'articles', :controller => 'articles', :action => 'index', :page => '1', :order => 'wiki_updated_at DESC', :category => 'all', :permanent => true
  
  map.connect 'admin/:action/:id', :controller => 'admin'
  map.connect 'admin/:action', :controller => 'admin'
  
  map.connect 'main/:action', :controller => 'main'
  
  # Routes for widgets that are named and tracked
  map.connect 'widget/tracking/:id/:location/:county', :controller => 'ask/widgets', :action => 'widget'
  map.connect 'widget/tracking/:id/:location', :controller => 'ask/widgets', :action => 'widget'
  map.connect 'widget/tracking/:id', :controller => 'ask/widgets', :action => 'widget'
  
  # Routes for widgets that are not named and tracked
  map.connect 'widget/:location/:county', :controller => 'ask/widgets', :action => 'widget'
  map.connect 'widget/:location', :controller => 'ask/widgets', :action => 'widget'
  map.connect 'widget', :controller => 'ask/widgets', :action => 'widget'  
  
  map.connect 'sitemap_index', :controller => 'feeds', :action => 'sitemap_index'
  map.connect 'sitemap_communities', :controller => 'feeds', :action => 'sitemap_communities'
  map.connect 'sitemap_pages', :controller => 'feeds', :action => 'sitemap_pages'
  map.connect 'sitemap_faq', :controller => 'feeds', :action => 'sitemap_faq'
  map.connect 'sitemap_events', :controller => 'feeds', :action => 'sitemap_events'
  map.connect 'feeds/:action', :controller => 'feeds', :requirements => {:action => /articles|article|faqs|events|all/}
  map.connect 'feeds/:action/-/*categories', :controller => 'feeds'
  map.connect 'feeds/:action/:type/*id', :controller => 'feeds'
  
  map.connect ':controller', :action => 'index'
  
  map.ask_an_expert 'expert/ask_an_expert', :controller => 'expert', :action => 'ask_an_expert'
  map.connection 'expert/:action', :controller => 'expert'
  map.connect 'expert/:action/:category', :controller => 'expert'

  map.category_index 'category/:category', :controller => 'main', :action => 'category'
  
  map.site_news ':category/news/:order/:page', :controller => 'articles', :action => 'news', :page => '1', :order => 'wiki_updated_at DESC', :requirements => { :page => /\d+/ }
  map.site_faqs ':category/faqs/:order/:page', :controller => 'faq', :action => 'index', :page => '1', :order => 'heureka_published_at DESC', :requirements => { :page => /\d+/ }
  map.site_articles ':category/articles/:order/:page', :controller => 'articles', :action => 'index', :page => '1', :order => 'wiki_updated_at DESC', :requirements => { :page => /\d+/ }
  map.site_events ':category/events/:state', :controller => 'events', :action => 'index', :state => ''
  map.site_events_month ':category/events/:year/:month/:state', :controller => 'events', :action => 'index', :state => ''
  
  map.site_learning_lessons ':category/learning_lessons/:order/:page', :controller => 'articles', :action => 'learning_lessons', :page => '1',:order => 'wiki_updated_at DESC', :requirements => { :page => /\d+/ }
  
  map.site_index ':category', :controller => 'main', :action => 'category'

  map.redirect 'wiki/*title', :controller => 'articles', :action => 'page', :permanent => true
  map.article_page 'article/:id', :controller => 'articles', :action => 'page', :requirements => { :id => /\d+/ }
  map.connect 'article/:id/print', :controller => 'articles', :action => 'page', :print => 1, :requirements => { :id => /\d+/ }
  map.wiki_page 'pages/*title', :controller => 'articles', :action => 'page'
  
  map.faq_page 'faq/:id', :controller => 'faq', :action => 'detail'
  map.events_page 'events/:id', :controller => 'events', :action => 'detail'
  map.connect 'faq/:id/print', :controller => 'faq', :action => 'detail', :print => 1
  map.connect 'events/:id/print', :controller => 'events', :action => 'detail', :print => 1
    
  map.connect 'faq/:year/:month/:day/:hour/:minute/:second', :controller => 'faq', :action => 'send_questions'
  
  map.connect ':controller/rest/*email', :action => 'rest'
  map.connect ':controller/:action'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  
  # this must be last
  map.connect '*path', :controller => 'application', :action => 'do_404', :requirements => { :path => /.*/ }
end
