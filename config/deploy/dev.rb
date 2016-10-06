set :deploy_to, "/services/articles/"
if(branch = ENV['BRANCH'])
  set :branch, branch
else
  set :branch, 'master'
end
set :vhost, 'dev-articles.extension.org'
set :deploy_server, 'dev-articles.aws.extension.org'
server deploy_server, :app, :web, :db, :primary => true
