#!/usr/bin/env ruby
require 'getoptlong'
require 'digest/md5'
### Program Options
progopts = GetoptLong.new(
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--previous","-p", GetoptLong::REQUIRED_ARGUMENT ],
  [ "--latest","-l", GetoptLong::REQUIRED_ARGUMENT ],
  [ "--branch","-b", GetoptLong::REQUIRED_ARGUMENT ],
  [ "--application","-a", GetoptLong::REQUIRED_ARGUMENT ],
  [ "--user","-u", GetoptLong::REQUIRED_ARGUMENT ],
  [ "--host","-h", GetoptLong::REQUIRED_ARGUMENT ],
  [ "--repository","-r", GetoptLong::REQUIRED_ARGUMENT ]
)

@gitcommand = '/usr/bin/git'
@environment = 'production'
progopts.each do |option, arg|
  case option
    when '--environment'
      @environment = arg
    when '--previous'
      @previous_release = arg
    when '--latest'
      @latest_release = arg
    when '--repository'
      @repository = arg
    when '--branch'
      @branch = arg
    when '--application'
      @application = arg
    when '--host'
      @host = arg
    when '--user'
      @user = arg
    else
      puts "Unrecognized option #{opt}"
      exit 0
    end
end
### END Program Options

if !ENV["RAILS_ENV"] || ENV["RAILS_ENV"] == ""
  ENV["RAILS_ENV"] = @environment
end

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

def runcommand(command)
  outputString command,"\n" if @verbose
  cmdoutput =  %x{#{command}}
  outputString cmdoutput if @verbose
  return cmdoutput
end

# let's go!
command = "#{@gitcommand} log --shortstat --summary #{@previous_release}..#{@latest_release}"
@scmoutput = runcommand(command)
#@scmoutput = 'TODO:'
@deployinfo = Hash.new
@deployinfo['application'] = @application
@deployinfo['host'] = @host
@deployinfo['repository'] = @repository
@deployinfo['version'] = "#{@branch} r#{@latest_release}"
@deployinfo['username'] = @user
@deployinfo['time'] = Time.now
@deployinfo['schema_version'] = ActiveRecord::Base.connection.select_value('SELECT MAX(CONVERT(version,UNSIGNED)) FROM schema_migrations').to_i
NotificationMailer.deliver_deployment(@deployinfo,@scmoutput)
  
