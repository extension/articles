require 'erb'
require 'yaml'

#------------------------------
# <i>Should</i> only have to edit these two vars for standard eXtension deployments

set :application, "darmok"
set :app_host, 'www'

#------------------------------

set :repository_base,  "https://sourcecode.extension.org/svn/#{application}"
set :deploy_via, :export
set :use_sudo, false

# Make sure environment is loaded as first step
on :load, "deploy:setup_environment"

# Disable our app before running the deploy
before "deploy", "deploy:web:disable"

# After code is updated, do some house cleaning
after "deploy:update_code", "deploy:update_maint_msg"
after "deploy:update_code", "deploy:link_configs"
after "deploy:update_code", "deploy:setup_app_version"
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

  # Read in environment settings and setup appropriate repository and
  # deployment settings.  After this is run you can expect all roles,
  # deploy dirs and repository variables to be properly set.
  task :setup_environment do
    
    # Make sure all necessary roles are defined, the repository location
    # is determined, and the deploy dir is set
    if(server_settings)
      setup_roles
      set :repository, build_repository_uri
      set :deploy_to, server_settings['deploy_dir']
      set :user, get_staff_username
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
    ln -nfs #{shared_path}/config/newrelic.yml #{release_path}/config/newrelic.yml &&
    rm -rf #{release_path}/tmp/attachment_fu &&
    ln -nfs #{shared_path}/upload/attachment_fu #{release_path}/tmp/attachment_fu
    CMD
  end

  desc "Setup the app version file (valid after an update code invocation)"
  task :setup_app_version, :roles => :app do
    puts "  * setting version info: #{version_tag} r#{latest_revision}"
    version_file = "#{release_path}/app/models/app_version.rb"
    version_file_contents = render "config/app_version.erb"
    put version_file_contents, version_file
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
  @server_settings ||=
    YAML.load(render('config/deploy_servers.yml'))[ENV['SERVER']]
end

# map local machine usernames to eX staff usernames
def get_staff_username
  user =
     YAML.load(render('config/deploy_user_map.yml'))[ENV['USER']]
  user ||= ENV['USER'] 
end

# Get the uri of the repository to pull from using the 
# specified environment variables
def build_repository_uri
  if (tag = (ENV['TAG'] || server_settings['tag']))
    set :version_tag, tag
    tag == 'trunk' ? "#{repository_base}/trunk" : "#{repository_base}/tags/#{tag}"
  elsif (branch = (ENV['BRANCH']))
    set :version_tag, "branches-#{branch}"
    branch == 'trunk' ? "#{repository_base}/trunk" : "#{repository_base}/branches/#{branch}"
  else
    set :version_tag, most_recent_svn_tag
    "#{repository_base}/tags/#{version_tag}"
  end
end

# Get is the most recent tagged version in the repository
def most_recent_svn_tag
  # -v includes the revision number in column 0, tag in column 5
  tag_list = `svn -v ls #{repository_base}/tags/`.split("\n")
  tag_list.collect!{|ea| ea.split().values_at(0,5)}
  tag_list.reject!{|ea| ea[1] == './'}
  tag_list.sort!{|x,y| x[0].to_i <=> y[0].to_i}
  tag_list.last.at(1).chomp('/')
end

# Backwards compatible 'render' from cap < 2.0
def render(file)
  ERB.new(File.read(File.dirname(__FILE__) + "/../#{file}")).result(binding)
end
