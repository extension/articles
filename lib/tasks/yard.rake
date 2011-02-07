require 'rubygems'
require 'yard'

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', 'app/**/*.rb', 'vendor/**/*.rb', 'script/*.rb']
end