set :deploy_to, "/services/apache/vhosts/www.extension.org/railsroot/"
set :branch, 'master'
server 'www.extension.org', :app, :web, :db, :primary => true