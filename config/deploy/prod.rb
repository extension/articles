set :deploy_to, "/services/articles/"
set :branch, 'master'
set :vhost, 'articles.extension.org'
server vhost, :app, :web, :db, :primary => true
set :port, 24
