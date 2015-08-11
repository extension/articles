set :deploy_to, "/services/articles/"
set :branch, 'musical_articles'
set :vhost, 'articles.extension.org'
server vhost, :app, :web, :db, :primary => true
