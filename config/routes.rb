ActionController::Routing::Routes.draw do |map|
  
  map.root :controller => 'main'
  map.home '', :controller => 'main', :action => 'index'
  
  #################################################################
  ### people routes ###
  
  # some named convenience routes
  map.welcome 'people', :controller => "people/welcome", :action => 'home'
  map.login 'people/login', :controller => 'people/account', :action => 'login'

  map.namespace :people do |people|
    people.connect 'colleagues/:action', :controller => :colleagues
    people.connect 'admin/:action', :controller => :admin
    people.connect 'signup', :controller => :signup, :action => :new
    people.connect 'activity/:action', :controller => :activity
    people.connect 'activity/:action/:id/:filter', :controller => :activity
    people.connect 'numbers/:action', :controller => :numbers
    people.connect 'invite/:invite', :controller => :signup, :action => :new
    people.connect 'sp/:token', :controller => :account, :action => :set_password
    people.connect 'help', :controller => :help
    people.resources :lists, :collection => {:showpost => :get, :all => :get, :managed => :get, :nonmanaged => :get, :postactivity => :get, :postinghelp => :get}, :member => { :posts => :get, :subscriptionlist => :get , :ownerlist => :get, }
    people.resources :communities, :collection => { :downloadlists => :get,  :filter => :get, :newest => :get, :mine => :get, :browse => :get, :tags => :get, :findcommunity => :get},
                              :member => {:userlist => :get, :invite => :any, :change_my_connection => :post, :modify_user_connection => :post, :xhrfinduser => :post, :editlists => :any, :describe => :any}
    people.resources :invitations,  :collection => {:mine => :get}
  end
  
  # openid related routing
  map.connect 'openid/xrds', :controller => 'opie', :action => 'idp_xrds'
  map.connect 'people/:extensionid', :controller => 'opie', :action => 'user'
  map.connect 'people/:extensionid/xrds', :controller => 'opie', :action => 'user_xrds'
  map.connect 'opie/:action', :controller => 'opie'
  map.connect 'opie/delegate/:extensionid', :controller => 'opie', :action => 'delegate'
    
  
  ################################################################
  ### AaE routes ###
    
  map.connect 'ask', :controller => 'ask', :action => 'index'
  
  map.ask_form 'ask', :controller => 'ask', :action => 'index'
  map.widget_submit_question 'widget_submit_question', :controller => 'widget', :action => 'create_from_widget'
  map.widget 'widget', :controller => 'widget', :action => 'index'
  #map.connect 'ask/who', :controller => 'ask/widgets', :action => 'who'
  #map.connect 'ask/about', :controller => 'ask/widgets', :action => 'about'
  #map.connect 'ask/documentation', :controller => 'ask/widgets', :action => 'documentation'
  #map.connect 'ask/help', :controller => 'ask/widgets', :action => 'help'
  #map.connect 'ask/profile/:id', :controller => 'ask/prefs', :action => 'profile'
  
  #################################################################
  ### pubsite routes ###
  map.connect 'main/:action', :controller => 'main'
  map.connect 'sitemap_index', :controller => 'feeds', :action => 'sitemap_index'
  map.connect 'sitemap_communities', :controller => 'feeds', :action => 'sitemap_communities'
  map.connect 'sitemap_pages', :controller => 'feeds', :action => 'sitemap_pages'
  map.connect 'sitemap_faq', :controller => 'feeds', :action => 'sitemap_faq'
  map.connect 'sitemap_events', :controller => 'feeds', :action => 'sitemap_events'
  map.connect 'feeds', :controller => 'feeds'
  map.connect 'feeds/:action', :controller => 'feeds', :requirements => {:action => /articles|article|faqs|events|all/}
  map.connect 'feeds/:action/-/*content_tags', :controller => 'feeds'
  map.connect 'feeds/:action/:type/*id', :controller => 'feeds'
  ## print routes
  map.connect 'article/:id/print', :controller => 'articles', :action => 'page', :print => 1, :requirements => { :id => /\d+/ }
  map.connect 'faq/:id/print', :controller => 'faq', :action => 'detail', :print => 1
  map.connect 'events/:id/print', :controller => 'events', :action => 'detail', :print => 1
  
  
  ### pubsite redirect routes
  map.redirect 'wiki/*title', :controller => 'articles', :action => 'page', :permanent => true
  map.redirect 'news', :controller => 'articles', :action => 'news', :content_tag => 'all', :permanent => true  
  map.redirect 'faqs', :controller => 'faq', :action => 'index', :content_tag => 'all', :permanent => true
  map.redirect 'articles', :controller => 'articles', :action => 'index', :content_tag => 'all', :permanent => true
  map.redirect 'expert/ask_an_expert', :controller => 'ask', :action => 'index', :permanent => true
  
  
  ### pubsite admin routes
  map.namespace :admin do |admin|
    admin.resources :sponsors, :collection => {:update_positions => :post}
    admin.resources :feed_locations
    admin.resources :logos
  end
  
  map.connect 'admin/:action/:id', :controller => 'admin'
  map.connect 'admin/:action', :controller => 'admin'

  ### pubsite named routes  
  map.logo  'logo/:file.:format', :controller => 'logo', :action => :display
  map.reports 'reports', :controller => :reports
  map.content_tag_index 'category/:content_tag', :controller => 'main', :action => 'content_tag'
  map.article_page 'article/:id', :controller => 'articles', :action => 'page', :requirements => { :id => /\d+/ }
  map.faq_page 'faq/:id', :controller => 'faq', :action => 'detail'
  map.events_page 'events/:id', :controller => 'events', :action => 'detail'
  map.wiki_page 'pages/*title', :controller => 'articles', :action => 'page'
  
  ### pubsite content_tag routes - should pretty much catch *everything* else right now
  map.site_news ':content_tag/news/:order/:page', :controller => 'articles', :action => 'news', :page => '1', :order => 'wiki_updated_at DESC', :requirements => { :page => /\d+/ }
  map.site_faqs ':content_tag/faqs/:order/:page', :controller => 'faq', :action => 'index', :page => '1', :order => 'heureka_published_at DESC', :requirements => { :page => /\d+/ }
  map.site_articles ':content_tag/articles/:order/:page', :controller => 'articles', :action => 'index', :page => '1', :order => 'wiki_updated_at DESC', :requirements => { :page => /\d+/ }
  map.site_events ':content_tag/events/:state', :controller => 'events', :action => 'index', :state => ''
  map.site_events_month ':content_tag/events/:year/:month/:state', :controller => 'events', :action => 'index', :state => ''
  map.site_learning_lessons ':content_tag/learning_lessons/:order/:page', :controller => 'articles', :action => 'learning_lessons', :page => '1',:order => 'wiki_updated_at DESC', :requirements => { :page => /\d+/ }
  map.site_index ':content_tag', :controller => 'main', :action => 'content_tag'
  
  ### catch?  I'm not sure that these are ever actually touched because of the :content_tag routes above
  map.connect ':controller', :action => 'index'
  map.connect ':controller/:action'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  
  # this must be last
  map.connect '*path', :controller => 'application', :action => 'do_404', :requirements => { :path => /.*/ }
end
