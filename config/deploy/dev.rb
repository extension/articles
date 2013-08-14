set :deploy_to, "/services/apache/vhosts/www.demo.extension.org/railsroot/"
if(branch = ENV['BRANCH'])
  set :branch, branch
else
  set :branch, 'development'
end
server 'www.demo.extension.org', :app, :web, :db, :primary => true
