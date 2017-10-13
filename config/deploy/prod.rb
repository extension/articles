set :deploy_to, "/services/articles/"
set :branch, 'master'
set :vhost, 'articles.extension.org'
set :deploy_server, 'articles.awsi.extension.org'
server deploy_server, :app, :web, :db, :primary => true
