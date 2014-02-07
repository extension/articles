set :deploy_to, "/services/www/"
if(branch = ENV['BRANCH'])
  set :branch, branch
else
  set :branch, 'ruby19rails3'
end
server 'dev-www.extension.org', :app, :web, :db, :primary => true
