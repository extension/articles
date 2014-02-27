set :deploy_to, "/services/www/"
set :branch, 'master'
server 'www.extension.org', :app, :web, :db, :primary => true