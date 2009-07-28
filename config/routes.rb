ActionController::Routing::Routes.draw do |map|
  
  map.root :controller => 'main'
  
  #map.resources :assets, :path_prefix => '/admin', :except => :show
  
  map.namespace :admin do |admin|
    admin.resources :sponsors, :collection => {:update_positions => :post}
    admin.resources :feed_locations
    admin.resources :logos
  end
  
  map.logo  'logo/:file.:format', :controller => 'logo', :action => :display
  #map.connect 'logo/:file.:format', :controller => "logo", :action => "display"
  
  map.home '', :controller => 'main', :action => 'index'
  map.redirect 'news', :controller => 'articles', :action => 'news', :page => '1', :order => 'wiki_updated_at DESC', :category => 'all', :permanent => true
  map.redirect 'faqs', :controller => 'faq', :action => 'index', :page => '1', :order => 'heureka_published_at DESC', :category => 'all', :permanent => true
  map.redirect 'articles', :controller => 'articles', :action => 'index', :page => '1', :order => 'wiki_updated_at DESC', :category => 'all', :permanent => true
  
  map.reports 'reports', :controller => :reports
  map.feeds 'reports', :controller => :feeds

  
  #################################################################
  ### people routes ###
  map.welcome 'people', :controller => "people/welcome", :action => 'home'
  map.connect 'people/admin/:action', :controller => 'people/admin'
  map.connect 'people/colleagues/:action', :controller => 'people/colleagues'
  map.connect 'people/activity/:action', :controller => 'people/activity'
  map.connect 'people/activity/:action/:id/:filter', :controller => 'people/activity'
  map.connect 'people/numbers/:action', :controller => 'people/numbers'

  map.connect 'people/signup', :controller => 'people/signup', :action => 'new'
  map.login 'people/login', :controller => 'people/account', :action => 'login'
  map.connect 'people/invite/:invite', :controller => 'people/signup', :action => 'new'
  #define some explicit routes until the current help pages are moved into a wiki
  map.connect 'people/help', :controller => 'people/help', :action => 'help'

  #set up the routes to handle help request pages
  map.connect 'people/help/:id', :controller => 'help', :action => 'index', :requirements =>{ :id =>/[\w\d\-.:,;()@ ]*((\/[\w\d\-.:,;()@ ]*))*?/}

  # token shortcuts
  map.connect 'people/sp/:token', :controller => 'people/account', :action => 'set_password'
  
  map.namespace :people do |people|  
    people.resources :lists, :collection => {:showpost => :get, :all => :get, :managed => :get, :nonmanaged => :get, :postactivity => :get, :postinghelp => :get}, :member => { :posts => :get, :subscriptionlist => :get , :ownerlist => :get, }
    people.resources :communities, :collection => { :downloadlists => :get,  :filter => :get, :newest => :get, :mine => :get, :browse => :get, :tags => :get, :findcommunity => :get},
                              :member => {:userlist => :get, :invite => :any, :change_my_connection => :post, :modify_user_connection => :post, :xhrfinduser => :post, :editlists => :any, :describe => :any}
    people.resources :invitations,  :collection => {:mine => :get}
  end
  
  # TODO - is this necessary?
  #map.connect 'colleagues/listing/:listtype/:id', :controller => 'colleagues', :action => 'listing'
  #map.connect 'feeds/community/:id/:filter', :controller => 'feeds', :action => 'community'

  map.connect 'openid/xrds', :controller => 'opie', :action => 'idp_xrds'
  map.connect 'people/:extensionid', :controller => 'opie', :action => 'user'
  map.connect 'people/:extensionid/xrds', :controller => 'opie', :action => 'user_xrds'
  map.connect 'opie/:action', :controller => 'opie'
  
  map.connect 'opie/delegate/:extensionid', :controller => 'opie', :action => 'delegate'

  #################################################################
  
  map.connect 'admin/:action/:id', :controller => 'admin'
  map.connect 'admin/:action', :controller => 'admin'
  
  map.connect 'main/:action', :controller => 'main'
  
  ################################################################
  ### AaE routes ###
  
  # Routes for widgets that are named and tracked
  map.connect 'widget/tracking/:id/:location/:county', :controller => 'ask/widgets', :action => 'widget'
  map.connect 'widget/tracking/:id/:location', :controller => 'ask/widgets', :action => 'widget'
  map.connect 'widget/tracking/:id', :controller => 'ask/widgets', :action => 'widget'
  
  # Routes for widgets that are not named and tracked
  map.connect 'widget/:location/:county', :controller => 'ask/widgets', :action => 'widget'
  map.connect 'widget/:location', :controller => 'ask/widgets', :action => 'widget'
  map.connect 'widget', :controller => 'ask/widgets', :action => 'widget'  
  
  map.connect 'ask', :controller => 'ask/widgets', :action => 'index'
  map.connect 'ask/who', :controller => 'ask/widgets', :action => 'who'
  map.connect 'ask/about', :controller => 'ask/widgets', :action => 'about'
  map.connect 'ask/documentation', :controller => 'ask/widgets', :action => 'documentation'
  map.connect 'ask/help', :controller => 'ask/widgets', :action => 'help'
  map.connect 'ask/profile/:id', :controller => 'ask/prefs', :action => 'profile'
  ################################################################
  
  map.connect 'sitemap_index', :controller => 'feeds', :action => 'sitemap_index'
  map.connect 'sitemap_communities', :controller => 'feeds', :action => 'sitemap_communities'
  map.connect 'sitemap_pages', :controller => 'feeds', :action => 'sitemap_pages'
  map.connect 'sitemap_faq', :controller => 'feeds', :action => 'sitemap_faq'
  map.connect 'sitemap_events', :controller => 'feeds', :action => 'sitemap_events'
  map.connect 'feeds/:action', :controller => 'feeds', :requirements => {:action => /articles|article|faqs|events|all/}
  map.connect 'feeds/:action/-/*categories', :controller => 'feeds'
  map.connect 'feeds/:action/:type/*id', :controller => 'feeds'
  
  map.content_tag_index 'category/:content_tag', :controller => 'main', :action => 'content_tag'
  
  map.site_news ':content_tag/news/:order/:page', :controller => 'articles', :action => 'news', :page => '1', :order => 'wiki_updated_at DESC', :requirements => { :page => /\d+/ }
  map.site_faqs ':content_tag/faqs/:order/:page', :controller => 'faq', :action => 'index', :page => '1', :order => 'heureka_published_at DESC', :requirements => { :page => /\d+/ }
  map.site_articles ':content_tag/articles/:order/:page', :controller => 'articles', :action => 'index', :page => '1', :order => 'wiki_updated_at DESC', :requirements => { :page => /\d+/ }
  map.site_events ':content_tag/events/:state', :controller => 'events', :action => 'index', :state => ''
  map.site_events_month ':content_tag/events/:year/:month/:state', :controller => 'events', :action => 'index', :state => ''
  
  map.site_learning_lessons ':content_tag/learning_lessons/:order/:page', :controller => 'articles', :action => 'learning_lessons', :page => '1',:order => 'wiki_updated_at DESC', :requirements => { :page => /\d+/ }
  
  map.site_index ':content_tag', :controller => 'main', :action => 'content_tag'

  map.redirect 'wiki/*title', :controller => 'articles', :action => 'page', :permanent => true
  map.article_page 'article/:id', :controller => 'articles', :action => 'page', :requirements => { :id => /\d+/ }
  map.connect 'article/:id/print', :controller => 'articles', :action => 'page', :print => 1, :requirements => { :id => /\d+/ }
  map.wiki_page 'pages/*title', :controller => 'articles', :action => 'page'
  
  map.faq_page 'faq/:id', :controller => 'faq', :action => 'detail'
  map.events_page 'events/:id', :controller => 'events', :action => 'detail'
  map.connect 'faq/:id/print', :controller => 'faq', :action => 'detail', :print => 1
  map.connect 'events/:id/print', :controller => 'events', :action => 'detail', :print => 1
    
  map.connect 'faq/:year/:month/:day/:hour/:minute/:second', :controller => 'faq', :action => 'send_questions'
  


  # catch requests to find
  map.connect 'find/:action/:id', :controller => 'colleagues'
  
  map.connect ':controller', :action => 'index'
  map.connect ':controller/rest/*email', :action => 'rest'
  map.connect ':controller/:action'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  
  # this must be last
  map.connect '*path', :controller => 'application', :action => 'do_404', :requirements => { :path => /.*/ }
end
