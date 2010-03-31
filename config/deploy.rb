require 'yaml'

#------------------------------
# <i>Should</i> only have to edit these three vars for standard eXtension deployments

set :application, "darmok"
set :user, 'pacecar'
set :localuser, ENV['USER']
#------------------------------

set :repository, "git@github.com:extension/#{application}.git"
set :scm, "git"
set :use_sudo, false
set :ruby, "/usr/bin/ruby"

# Make sure environment is loaded as first step
on :load, "deploy:setup_environment"

# Disable our app before running the deploy
before "deploy", "deploy:web:disable"

# After code is updated, do some house cleaning
after "deploy:update_code", "deploy:update_maint_msg"
after "deploy:update_code", "deploy:link_configs"
after "deploy:update_code", "deploy:cleanup"

# don't forget to turn it back on
after "deploy", "deploy:web:enable"
after "deploy", 'deploy:notification:email'

# Add tasks to the deploy namespace
namespace :deploy do
  
  desc "Deploy the #{application} application with migrations"
  task :default, :roles => :app do
        
    # Invoke deployment with migrations
    deploy.migrations
  end

  # Read in environment settings and setup appropriate repository and
  # deployment settings.  After this is run you can expect all roles,
  # deploy dirs and repository variables to be properly set.
  task :setup_environment do
    
    # Make sure all necessary roles are defined, the repository location
    # is determined, and the deploy dir is set
    if(server_settings)
      setup_roles
      set :deploy_to, server_settings['deploy_dir']
      if (branch = (ENV['BRANCH']))
        set :branch, branch
      else
        set :branch, server_settings['branch'] 
      end
      ssh_options[:port] = server_settings['ssh_port'] if server_settings['ssh_port']
      puts "  * Operating on: #{server_settings['host']}:#{deploy_to} from #{repository} as user: #{user}"
    else
      puts "  * WARNING: There is no 'SERVER' environment variable that matches an entry in the deploy_servers.yml file.  This will cause problems if you are attempting to execute a remote command."
    end      
  end

  # Override default restart task
  desc "Restart #{application} mod_rails"
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
    ln -nfs #{shared_path}/config/robots.txt #{release_path}/public/robots.txt &&
    ln -nfs #{shared_path}/config/appconfig.yml #{release_path}/config/appconfig.yml &&
    rm -rf #{release_path}/tmp/attachment_fu &&
    ln -nfs #{shared_path}/upload/attachment_fu #{release_path}/tmp/attachment_fu &&
    ln -nfs #{shared_path}/wikifiles #{release_path}/public/mediawiki    
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

  # generate an email to notify various users that a new version has been deployed
  namespace :notification do
    desc "Generate an email for the deploy"
    task :email, :roles => [:app] do 
      run "#{ruby} #{release_path}/script/deploynotification.rb -r #{repository} -a #{application} -h #{server_settings['host']} -u #{localuser} -p #{previous_revision} -l #{latest_revision} -b #{branch}"
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

#--------------------------------------------------------------------------
# Repository URI helper methods - specifically for the eXtension deployment
# environment and best practices
#--------------------------------------------------------------------------

# Setup the app, db and web roles (all currently just point to the
# same host name)
def setup_roles
  [:app, :db, :web].each do |role_name|
    role role_name, server_settings['host'], :primary => true
  end
end

# Get the server settings specified in ./deploy_servers.yml
# NOTE: will probably want to allow the user to specify where their
# deploy_servers.yml file is in the future?
def server_settings
  @server_settings ||= YAML.load_file('config/deploy_servers.yml')[ENV['SERVER']]
end



