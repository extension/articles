set :deploy_to, "/services/articles/"
set :branch, 'master'
set :vhost, 'articles.extension.org'
set :deploy_server, 'articles.aws.extension.org'
server deploy_server, :app, :web, :db, :primary => true
