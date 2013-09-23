set :stages, %w(prod dev)
set :default_stage, "dev"
require 'capistrano/ext/multistage'

# added by capatross generate_config
require 'capatross'
require "bundler/capistrano"
require 'yaml'
require 'airbrake/capistrano'

#------------------------------
# <i>Should</i> only have to edit these three vars for standard eXtension deployments

set :application, "darmok"
set :user, 'pacecar'
set :localuser, ENV['USER']
#------------------------------

set :repository, "git@github.com:extension/#{application}.git"
set :scm, "git"
set :use_sudo, false
set :ruby, "/usr/local/bin/ruby"
ssh_options[:forward_agent] = true
set :port, 24
set :bundle_flags, '--deployment --binstubs'

# Disable our app before running the deploy
before "deploy", "deploy:web:disable"

# After code is updated, do some house cleaning
after "deploy:update_code", "deploy:update_maint_msg"
after "deploy:update_code", "deploy:link_configs"
after "deploy:update_code", "deploy:cleanup"

# don't forget to turn it back on
after "deploy", "deploy:web:enable"

# Add tasks to the deploy namespace
namespace :deploy do
  
  desc "Deploy the #{application} application with migrations"
  task :default, :roles => :app do
    # Invoke deployment with migrations
    deploy.migrations
  end



  # Override default restart task
  desc "Restart passenger"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end

  desc "Update maintenance mode page/graphics (valid after an update code invocation)"
  task :update_maint_msg, :roles => :app do
     invoke_command "cp -f #{release_path}/public/maintenancemessage.html #{shared_path}/system/maintenancemessage.html"
  end
  
  desc "Link up various configs (valid after an update code invocation)"
  task :link_configs, :roles => :app do
    run <<-CMD
    rm -rf #{release_path}/config/database.yml #{release_path}/index &&
    rm -rf #{release_path}/public/robots.txt &&
    rm -rf #{release_path}/config/appconfig.yml &&
    ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml &&
    ln -nfs #{shared_path}/config/newrelic.yml #{release_path}/config/newrelic.yml &&
    ln -nfs #{shared_path}/config/robots.txt #{release_path}/public/robots.txt &&
    ln -nfs #{shared_path}/config/appconfig.yml #{release_path}/config/appconfig.yml &&
    rm -rf #{release_path}/tmp/attachment_fu &&
    ln -nfs #{shared_path}/upload/attachment_fu #{release_path}/tmp/attachment_fu &&
    ln -nfs #{shared_path}/wikifiles #{release_path}/public/mediawiki &&
    ln -nfs #{shared_path}/sites #{release_path}/public/sites &&   
    ln -nfs #{shared_path}/data #{release_path}/data &&
    rm -rf #{release_path}/public/sitemaps &&
    ln -nfs #{shared_path}/sitemaps #{release_path}/public/sitemaps &&
    ln -nfs #{shared_path}/omniauth #{release_path}/tmp/omniauth
    CMD
  end
  
    # Override default web enable/disable tasks
  namespace :web do
    
    desc "Put Apache in maintenancemode by touching the system/maintenancemode file"
    task :disable, :roles => :app do
      invoke_command "touch #{shared_path}/system/maintenancemode"
    end
  
    desc "Remove Apache from maintenancemode by removing the system/maintenancemode file"
    task :enable, :roles => :app do
      invoke_command "rm -f #{shared_path}/system/maintenancemode"
    end
    
  end

end

#--------------------------------------------------------------------------
# useful administrative routines
#--------------------------------------------------------------------------

namespace :admin do
  
  desc "Open up a remote console to #{application} (be sure to set your RAILS_ENV appropriately)"
  task :console, :roles => :app do
    input = ''
    invoke_command "cd #{current_path} && ./script/console #{ENV['RAILS_ENV'] || 'production'}" do |channel, stream, data|
      next if data.chomp == input.chomp || data.chomp == ''
      print data
      channel.send_data(input = $stdin.gets) if data =~ /^(>|\?)>/
    end
  end

  desc "Tail the server logs for #{application}"
  task :tail_logs, :roles => :app do
    run "tail -f #{shared_path}/log/production.log" do |channel, stream, data|
      puts  # for an extra line break before the host name
      puts "#{channel[:host]}: #{data}" 
      break if stream == :err    
    end
  end
end




