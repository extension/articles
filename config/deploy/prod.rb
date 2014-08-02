set :deploy_to, "/services/frontporch/"
set :branch, 'master'
set :vhost, 'www.extension.org'
server vhost, :app, :web, :db, :primary => true
