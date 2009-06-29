#!/usr/bin/env ruby
require 'getoptlong'

### Program Options
progopts = GetoptLong.new(
  [ "--environment","-e", GetoptLong::OPTIONAL_ARGUMENT ],
  [ "--refreshall","-r", GetoptLong::NO_ARGUMENT ],
  [ "--questiontype","-q", GetoptLong::OPTIONAL_ARGUMENT ]
)

@environment = 'production'
@refreshall = false
@questiontype = 'all'
progopts.each do |option, arg|
  case option
    when '--environment'
      @environment = arg
    when '--questiontype'
      @questiontype = arg
    when '--refreshall'
      @refreshall = true
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


###### go! ###########
if(@questiontype == 'all')
  questiontypes = ['faq','aae']
else
  questiontypes = [@questiontype]
end

questiontypes.each do |qtype|
  result = SearchQuestion.retrieve_questions(qtype,@refreshall)
end