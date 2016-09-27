set :deploy_to, "/services/articles/"
if(branch = ENV['BRANCH'])
  set :branch, branch
else
  set :branch, 'master'
end
set :vhost, 'dev-articles.awsi.extension.org'
server vhost, :app, :web, :db, :primary => true
set :port, 22
