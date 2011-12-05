
class FixSourceUrls < ActiveRecord::Migration
  class CreateUrlAlias < ActiveRecord::Base
    # connects to the create database
    self.establish_connection :create
    self.set_table_name 'url_alias'
    self.set_primary_key "pid"
  end
  
  def self.up  
    say_with_time "Fixing source urls" do 
      list = CreateUrlAlias.where("source LIKE '%node%'").all
      found_count = 0
      destroyed_count = 0
      list.each do |create_url_alias|
        match_url = 'http://create.extension.org/' + CGI.escape(create_url_alias.alias)
        if(page = Page.find_by_source_url(match_url))
          new_source_url = 'http://create.extension.org/' + create_url_alias.source
          fingerprint = Digest::SHA1.hexdigest(new_source_url.downcase)
          page.source_url = new_source_url
          page.source_url_fingerprint = fingerprint
          if(duplicate_page = Page.find_by_source_url_fingerprint(fingerprint))
            duplicate_page.destroy
            destroyed_count += 1
          end
          page.save
          found_count += 1
        end
      end
      say "Fixed #{found_count} articles, had to remove #{destroyed_count} duplicates."
    end
    
    say_with_time "Fixing data items" do
      MigratedUrl.all.each do |migrated_url|
        begin
          uri = URI.parse(migrated_url.alias_url)
        rescue
          if(migrated_url.alias_url =~ %r{http://cop.extension.org/wiki/(.*)})
            migrated_url.update_attribute(:alias_url, "http://cop.extension.org/wiki/#{CGI.escape($1)}")
          end
        end
      end
    end
  end

  def self.down
  end
end
