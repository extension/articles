set :deploy_to, "/services/frontporch/"
if(branch = ENV['BRANCH'])
  set :branch, branch
else
  set :branch, 'master'
end
set :vhost, 'dev-www.extension.org'
server vhost, :app, :web, :db, :primary => true
