set :stages, %w(prod dev)
set :default_stage, "dev"
require 'capistrano/ext/multistage'
require 'capatross'
require "bundler/capistrano"

TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'yes','YES','y','Y']
FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE','no','NO','n','N']

set :application, "articles"
set :user, 'pacecar'
set :gateway, 'deploy.extension.org'
set :repository, "git@github.com:extension/articles.git"
set :scm, "git"
set :use_sudo, false
set :keep_releases, 5
ssh_options[:forward_agent] = true
set :bundle_flags, '--deployment --binstubs'

before "deploy", "deploy:checks:git_push"
if(TRUE_VALUES.include?(ENV['MIGRATE']))
  before "deploy", "deploy:web:disable"
  before "deploy", "sidekiq:stop"
  after "deploy:update_code", "deploy:link_and_copy_configs"
  after "deploy:update_code", "deploy:cleanup"
  after "deploy:update_code", "deploy:migrate"
  after "deploy", "sidekiq:start"
  after "deploy", "deploy:web:enable"
else
  before "deploy", "deploy:checks:git_migrations"
  before "deploy", "sidekiq:stop"
  after "deploy:update_code", "deploy:link_and_copy_configs"
  after "deploy:update_code", "deploy:cleanup"
  after "deploy", "sidekiq:start"
end

# Add tasks to the deploy namespace
namespace :deploy do

  # Override default restart task
  desc "Restart passenger"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end

  desc "Link up various configs (valid after an update code invocation)"
  task :link_and_copy_configs, :roles => :app do
    run <<-CMD
    ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml &&
    ln -nfs #{shared_path}/config/robots.txt #{release_path}/public/robots.txt &&
    ln -nfs #{shared_path}/config/settings.local.yml #{release_path}/config/settings.local.yml &&
    ln -nfs #{shared_path}/config/honeybadger.yml #{release_path}/config/honeybadger.yml &&
    rm -rf #{release_path}/tmp/attachment_fu &&
    ln -nfs #{shared_path}/uploads #{release_path}/tmp/attachment_fu &&
    ln -nfs #{shared_path}/wikifiles #{release_path}/public/mediawiki/files &&
    ln -nfs #{shared_path}/drupalfiles #{release_path}/public/sites/default/files &&
    ln -nfs #{shared_path}/data #{release_path}/data &&
    ln -nfs #{shared_path}/sitemaps #{release_path}/public/sitemaps &&
    ln -nfs #{shared_path}/tmpcache    #{release_path}/tmp/cache &&
    ln -nfs #{shared_path}/tmpauth #{release_path}/tmp/auth
    CMD
  end

  # Override default web enable/disable tasks
  namespace :web do

    desc "Put Apache and Cronmon in maintenancemode by touching the maintenancemode file"
    task :disable, :roles => :app do
      invoke_command "touch /services/maintenance/#{vhost}.maintenancemode"
      invoke_command "touch /services/maintenance/CRONMONHALT"
    end

    desc "Remove Apache and Cronmon from maintenancemode by removing the maintenancemode file"
    task :enable, :roles => :app do
      invoke_command "rm -f /services/maintenance/#{vhost}.maintenancemode"
      invoke_command "rm -f /services/maintenance/CRONMONHALT"
    end

  end

  namespace :checks do
    desc "check to see if the local branch is ahead of the upstream tracking branch"
    task :git_push, :roles => :app do
      branch_status = `git status --branch --porcelain`.split("\n")[0]

      if(branch_status =~ %r{^## (\w+)\.\.\.([\w|/]+) \[(\w+) (\d+)\]})
        if($3 == 'ahead')
          logger.important "Your local #{$1} branch is ahead of #{$2} by #{$4} commits. You probably want to push these before deploying."
          $stdout.puts "Do you want to continue deployment? (Y/N)"
          unless (TRUE_VALUES.include?($stdin.gets.strip))
            logger.important "Stopping deployment by request!"
            exit(0)
          end
        end
      end
    end

    desc "check to see if there are migrations in origin/branch "
    task :git_migrations, :roles => :app do
      diff_stat = `git --no-pager diff --shortstat #{current_revision} #{branch} db/migrate`.strip

      if(!diff_stat.empty?)
        diff_files = `git --no-pager diff --summary #{current_revision} #{branch} db/migrate`
        logger.info "Your local #{branch} branch has migration changes and you did not specify MIGRATE=true for this deployment"
        logger.info "#{diff_files}"
      end
    end
  end

end

namespace :sidekiq do
  desc 'Stop sidekiq'
  task 'stop', :roles => :app do
    # check status
    started = false
    invoke_command 'status workers' do |channel,stream,data|
      started = (data =~ %r{start})
    end
    if(started)
      invoke_command 'stop workers', via: 'sudo'
    end
  end

  desc 'Start sidekiq'
  task 'start', :roles => :app do
    stopped = false
    invoke_command 'status workers' do |channel,stream,data|
      stopped = (data =~ %r{stop})
    end
    if(stopped)
      invoke_command 'start workers', via: 'sudo'
    end
  end

  desc 'Restart sidekiq'
  task 'restart', :roles => :app do
    stop
    start
  end
end
