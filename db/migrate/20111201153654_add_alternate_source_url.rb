class AddAlternateSourceUrl < ActiveRecord::Migration
  def self.up
    # for link rel="alternate" handling
    # there's some wonder here that if this is not enforced as unique
    # will that bite us later?  I'm thinking that the overhead of 
    # adding a unique fingerprint is a greater problem than what 
    # will happen if the source system doesn't enforce an unique
    # constraint on the alternate url
    add_column("pages", 'alternate_source_url', :text)    
    execute "UPDATE pages SET alternate_source_url = source_url"
  end

  def self.down
  end
end
