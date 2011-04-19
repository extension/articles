ActionController::Routing::Routes.draw do |map|
  
  map.root :controller => 'main'
  map.home '', :controller => 'main', :action => 'index'
  
  # notices
  map.connect 'notice/ask', :controller => 'notice', :action => 'ask'

  
  #################################################################
  ### people routes ###
  
  # some named convenience routes
  map.login 'people/login', :controller => 'people/account', :action => 'login'

  map.namespace :people do |people|
    people.welcome '/', :controller => :welcome, :action => :home
    people.notice  'welcome/notice', :controller => :welcome, :action => :notice
    people.contact 'help', :controller => :help
    people.connect 'colleagues/:action', :controller => :colleagues
    people.connect 'admin/:action', :controller => :admin
    people.connect 'signup', :controller => :signup, :action => :readme
    people.connect 'activity/:action', :controller => :activity
    people.connect 'activity/:action/:id/:filter', :controller => :activity
    people.connect 'numbers/:action', :controller => :numbers
    people.connect 'invite/:invite', :controller => :signup, :action => :readme
    people.connect 'sp/:token', :controller => :account, :action => :set_password
    people.apikeys 'profile/apikeys', :controller => :profile, :action => :apikeys
    people.apikey 'profile/apikey/:id', :controller => :profile, :action => :apikey
    people.new_apikey 'profile/new_apikey', :controller => :profile, :action => :new_apikey
    people.edit_apikey 'profile/edit_apikey/:id', :controller => :profile, :action => :edit_apikey
    people.connect 'lists/postinghelp', :controller => :lists, :action => :postinghelp
    people.connect 'lists/about', :controller => :lists, :action => :about
    people.connect 'lists/:id', :controller => :lists, :action => :show, :requirements => { :id => /\d+/ }  
    people.connect 'lists', :controller => :lists, :action => :index

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
  # requires that if there is a parameter after the /ask, that it is in hexadecimal representation
  map.ask_question 'ask/:fingerprint', :controller => 'ask', :action => 'question', :requirements => { :fingerprint => /[[:xdigit:]]+/ }
  
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
     aae.connect 'expertise/experts_by_category/:legacycategory', :controller => :expertise, :action => :experts_by_category
     aae.connect 'search/:action/:id', :controller => :search
     aae.connect 'question/escalation_report/:legacycategory', :controller => :question, :action => :escalation_report
     aae.question 'question/:id', :controller => :question, :action => :index, :requirements => { :id => /\d+/ }     
     aae.connect 'question/:action/:id', :controller => :question
     aae.submitterquestions 'questions/submitter/:account', :controller => :questions, :action => :submitter
     aae.connect 'help', :controller => :help
     aae.connect 'feeds/:action/:legacycategory', :controller => :feeds
     aae.home '/', :controller => :home, :action => :index     
  end
  
  # redirect
  map.redirect 'aae/admin', :controller => 'admin', :action => 'index', :permanent => true
  
  
  ### AaE API ###
  map.connect 'api/aae/ask.json', :controller => 'api/aae', :action => :ask  
    
  ### Widget iFrame ###
  map.widget_submit_question 'widget_submit_question', :controller => 'widget', :action => 'create_from_widget'
  
  # route for existing bonnie_plants widget for continued operation.
  map.connect 'widget/bonnie_plants/tracking/:widget', :controller => 'widget', :action => 'index'
  # Route for named/tracked widget w/ no location *unused is a catcher for /location and /location/county for
  # existing widgets, since we aren't using that in the URL anymore
  map.widget_tracking 'widget/tracking/:widget/*unused', :controller => 'widget', :action => 'index'
  # recognize widget/index as well
  map.connect 'widget/index/:widget/*unused', :controller => 'widget', :action => 'index'
  # Widget route for unnamed/untracked widgets
  map.widget 'widget', :controller => 'widget', :action => 'index'

  map.connect 'widget/create_from_widget', :controller => 'widget', :action => 'create_from_widget'
  
  ### Widget Stuff ###
  # redirects
  map.redirect 'aae/widgets', :controller => 'widgets/aae', :action => 'index', :permanent => true
  map.redirect 'aae/widgets/:redirectparam', :controller => 'widgets/aae', :action => 'redirector', :permanent => true
  map.namespace :widgets do |widgets|
    widgets.aae 'aae', :controller => :aae, :action => 'index'
    widgets.content 'content', :controller => :content, :action => 'index'
    widgets.home '/', :controller => :home, :action => :index     
    widgets.view_aae 'aae/view/:id', :controller => :aae, :action => 'view'
    widgets.edit_aae 'aae/edit/:id', :controller => :aae, :action => 'edit'
  end

  ### Search Stuff ###

  map.search 'search', :controller => 'search', :action => 'index'
  map.annotation_event_page 'search/manage_event/:id', :controller => 'search', :action => 'manage_event'

  ### Learn Stuff ###
  map.learn 'learn', :controller => 'learn', :action => 'index'
  map.learn_session 'learn/event/:id', :controller => :learn, :action => :event
  map.connect 'learn/events', :controller => :learn, :action => :events
  map.connect 'learn/events/:sessiontype', :controller => :learn, :action => :events

  ## Debug ##
  map.debuglocation 'debug/location', :controller => 'debug', :action => 'location'


  #################################################################
  ### pubsite routes ###
  map.connect 'main/:action', :controller => 'main'
  map.connect 'feeds', :controller => 'feeds'
    
  map.redirect 'feeds/articles', :controller => 'feeds', :action => 'content', :content_types => 'articles', :permanent => true  
  map.redirect 'feeds/faqs', :controller => 'feeds', :action => 'content', :content_types => 'faqs', :permanent => true  
  map.redirect 'feeds/events', :controller => 'feeds', :action => 'content', :content_types => 'events', :permanent => true  
  map.redirect 'feeds/all', :controller => 'feeds', :action => 'content', :permanent => true  

  map.connect 'feeds/community/-/:tags', :controller => 'feeds', :action => 'community'
  map.content_feed 'feeds/content/:tags', :controller => 'feeds', :action => 'content'
  map.connect 'feeds/:action', :controller => 'feeds'
  

  
  ### pubsite redirect routes
  map.redirect 'wiki/*title', :controller => 'articles', :action => 'page', :permanent => true
  map.redirect 'news', :controller => 'pages', :action => 'news', :content_tag => 'all', :permanent => true  
  map.redirect 'faqs', :controller => 'pages', :action => 'faqs', :content_tag => 'all', :permanent => true
  map.redirect 'articles', :controller => 'pages', :action => 'articles', :content_tag => 'all', :permanent => true
  map.redirect 'expert/ask_an_expert', :controller => 'ask', :action => 'index', :permanent => true
  
  
  ### pubsite admin routes
  map.namespace :admin do |admin|
    admin.resources :sponsors, :collection => {:update_positions => :post}
    admin.resources :feed_locations
    admin.resources :logos
  end
  
  map.connect 'admin/:action/:id', :controller => 'admin'
  map.connect 'admin/:action', :controller => 'admin'
  
  ### connect up "data" to the api/data controller
  map.connect 'data/:action', :controller => 'api/data'
  
  ### current routes for specific content
  map.pagelist 'pages/list', :controller => 'pages', :action => 'list'
  map.connect 'pages/update_time_zone/:id', :controller => 'pages', :action => 'update_time_zone', :requirements => { :id => /\d+/ }
  map.print_pageid 'pages/:id/print', :controller => 'pages', :action => 'show', :requirements => { :id => /\d+/ }
  map.pageid 'pages/:id', :controller => 'pages', :action => 'show', :requirements => { :id => /\d+/ }
  map.print_page 'pages/:id/:title/print', :controller => 'pages', :action => 'show', :print => 1
  map.page 'pages/:id/:title', :controller => 'pages', :action => 'show', :requirements => { :id => /\d+/ }

  ### old routes for specific content
  map.connect 'article/:id/print', :controller => 'pages', :action => 'redirect_article', :print => 1, :requirements => { :id => /\d+/ }
  map.connect 'article/:id', :controller => 'pages', :action => 'redirect_article', :requirements => { :id => /\d+/ }
  map.connect 'events/:id/print', :controller => 'pages', :action => 'redirect_event', :print => 1
  map.connect 'events/:id', :controller => 'pages', :action => 'redirect_event'
  map.connect 'faq/:id/print', :controller => 'pages', :action => 'redirect_faq', :print => 1
  map.connect 'faq/:id', :controller => 'pages', :action => 'redirect_faq'  
  map.connect 'pages/*title', :controller => 'pages', :action => 'redirect_article'

  # more named routes
  map.logo  'logo/:file.:format', :controller => 'logo', :action => :display
  map.reports 'reports', :controller => :reports
  map.content_tag_index 'category/:content_tag', :controller => 'main', :action => 'content_tag'
  
  # wiki compatibility version
  map.preview_wikipage 'preview/pages/*title', :controller => 'preview', :action => 'showpage' # note :title is ignored in the method, and the URI is gsub'd because of '?' characters
  # everyone else
  map.preview_page 'preview/page/:source/:source_id', :controller => 'preview', :action => 'showpage'
   
  map.preview_tag 'preview/:content_tag', :controller => 'preview', :action => 'content_tag'
  map.preview_category 'preview/showcategory/:categorystring', :controller => 'preview', :action => 'showcategory'
  map.preview_home 'preview', :controller => 'preview', :action => 'index'

  map.pageinfo_pagelinklist 'pageinfo/pagelinklist/:content_tag', :controller => 'pageinfo', :action => 'pagelinklist'
  map.pageinfo_pagelist 'pageinfo/pagelist/:content_tag', :controller => 'pageinfo', :action => 'pagelist'
  map.pageinfo_page 'pageinfo/:id', :controller => 'pageinfo', :action => 'show'

  # legacy routes to 410
  map.connect ':content_tag/events/:state', :controller => 'main', :action => 'do_410'
  map.connect ':content_tag/events/:year/:month/:state', :controller => 'main', :action => 'do_410'
  
  
  ### pubsite content_tag routes - should pretty much catch *everything* else right now
  map.site_news ':content_tag/news', :controller => 'pages', :action => 'news'
  map.site_faqs ':content_tag/faqs', :controller => 'pages', :action => 'faqs'
  map.site_articles ':content_tag/articles', :controller => 'pages', :action => 'articles'
  map.site_events ':content_tag/events', :controller => 'pages', :action => 'events'
  map.site_learning_lessons ':content_tag/learning_lessons', :controller => 'pages', :action => 'learning_lessons'

  map.short_pageid ':id', :controller => 'pages', :action => 'show',  :requirements => { :id => /\d+/ }
  map.site_index ':content_tag', :controller => 'main', :action => 'content_tag'
  
  ### catch?  I'm not sure that these are ever actually touched because of the :content_tag routes above
  map.connect ':controller', :action => 'index'
  map.connect ':controller/:action'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  
  # this must be last
  map.connect '*path', :controller => 'application', :action => 'do_404', :requirements => { :path => /.*/ }
end
