set :deploy_to, "/services/www/"
if(branch = ENV['BRANCH'])
  set :branch, branch
else
  set :branch, 'master'
end
server 'dev-www.extension.org', :app, :web, :db, :primary => true
