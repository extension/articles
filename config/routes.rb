ActionController::Routing::Routes.draw do |map|
  
  map.root :controller => 'main'
  map.home '', :controller => 'main', :action => 'index'
  
  #################################################################
  ### people routes ###
  
  # some named convenience routes
  map.login 'people/login', :controller => 'people/account', :action => 'login'

  map.namespace :people do |people|
    people.welcome '/', :controller => :welcome, :action => :home
    people.connect 'colleagues/:action', :controller => :colleagues
    people.connect 'admin/:action', :controller => :admin
    people.connect 'signup', :controller => :signup, :action => :new
    people.connect 'activity/:action', :controller => :activity
    people.connect 'activity/:action/:id/:filter', :controller => :activity
    people.connect 'numbers/:action', :controller => :numbers
    people.connect 'invite/:invite', :controller => :signup, :action => :new
    people.connect 'sp/:token', :controller => :account, :action => :set_password
    people.connect 'help', :controller => :help
    people.resources :lists, :collection => {:showpost => :get, :all => :get, :managed => :get, :nonmanaged => :get, :postactivity => :get, :postinghelp => :get, :about => :get}, :member => { :posts => :get, :subscriptionlist => :get , :ownerlist => :get, }
    people.resources :communities, :collection => { :downloadlists => :get,  :filter => :get, :newest => :get, :mine => :get, :browse => :get, :tags => :get, :findcommunity => :get},
                              :member => {:userlist => :get, :invite => :any, :change_my_connection => :post, :modify_user_connection => :post, :xhrfinduser => :post, :editlists => :any }
    people.resources :invitations,  :collection => {:mine => :get}
  end
  
  # openid related routing
  map.connect 'openid/xrds', :controller => 'opie', :action => 'idp_xrds'
  map.connect 'people/:extensionid', :controller => 'opie', :action => 'user'
  map.connect 'people/:extensionid/xrds', :controller => 'opie', :action => 'user_xrds'
  map.connect 'opie/:action', :controller => 'opie'
  map.connect 'opie/delegate/:extensionid', :controller => 'opie', :action => 'delegate'
    
  
  ################################################################
  ### AaE ###
  
  map.ask_form 'ask', :controller => 'ask', :action => 'index'
  map.incoming 'aae/incoming', :controller => 'aae/incoming', :action => 'index'
  map.my_assigned 'aae/my_assigned', :controller => 'aae/my_assigned', :action => 'index'
  map.my_resolved 'aae/my_resolved', :controller => 'aae/my_resolved', :action => 'index'
  map.resolved 'aae/resolved', :controller => 'aae/resolved', :action => 'index'
  map.spam 'aae/spam_list', :controller => 'aae/spam_list', :action => 'index'
  map.view_search_question 'aae/search', :controller => 'aae/search', :action => 'index'
  map.answer_question 'aae/question/answer', :controller => 'aae/question', :action => 'answer'
  map.aae_name_search 'aae/name_search', :controller => 'aae/search', :action => 'enable_search_by_name'
  map.aae_cat_loc_search 'aae/cat_loc_search', :controller => 'aae/search', :action => 'enable_search_by_cat_loc'
  map.aae_answer_search 'aae/search/answers', :controller => 'aae/search', :action => 'answers'
  map.aae_answer 'aae/search/answer', :controller => 'aae/search', :action => 'answer'
  map.aae_profile 'aae/profile', :controller => 'aae/profile', :action => 'index'
  map.aae_show_profile 'aae/profile/show_profile', :controller => 'aae/profile', :action => 'show_profile'
  map.aae_reserve_question 'aae/question/reserve_question/:sq_id', :controller => 'aae/question', :action => 'reserve_question'
  map.aae_report_spam 'aae/question/report_spam', :controller => 'aae/question', :action => 'report_spam'
  map.aae_report_ham  'aae/question/report_ham', :controller => 'aae/question', :action => 'report_ham'
  
  map.namespace :aae do |aae|
     aae.connect 'search/experts_by_category/:legacycategory', :controller => :search, :action => :experts_by_category
     aae.connect 'search/:action/:id', :controller => :search
     aae.connect 'question/escalation_report/:legacycategory', :controller => :question, :action => :escalation_report
     aae.question 'question/:id', :controller => :question, :action => :index, :requirements => { :id => /\d+/ }     
     aae.connect 'question/:action/:id', :controller => :question
     aae.connect 'help', :controller => :help
     aae.connect 'feeds/:action/:legacycategory', :controller => :feeds
     aae.home '/', :controller => :home, :action => :index     
  end
  
  ### Widget iFrame ###
  
  map.widget_submit_question 'widget_submit_question', :controller => 'widget', :action => 'create_from_widget'
  map.widget 'widget', :controller => 'widget', :action => 'index'
  # Routes for widgets that are named and tracked
  map.connect 'widget/tracking/:id/:location/:county', :controller => 'widget', :action => 'index'
  map.connect 'widget/tracking/:id/:location', :controller => 'widget', :action => 'index'
  map.connect 'widget/tracking/:id', :controller => 'widget', :action => 'index'
  
  # Routes for widgets that are not named and tracked and have just location info
  map.connect 'widget/:location/:county', :controller => 'widget', :action => 'index'
  map.connect 'widget/:location', :controller => 'widget', :action => 'index'
  
  ### Widget Stuff ###
  
  map.view_widget 'aae/widgets/view/:id', :controller => 'aae/widgets', :action => 'view'
  map.widget_home 'aae/widgets', :controller => 'aae/widgets', :action => 'index'
  
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
