class MakeEventsLocal < ActiveRecord::Migration
  def self.up
    if(ps = PageSource.where(:name => 'copevents').first)
      ps.destroy
    end
    execute "UPDATE pages SET source_id = NULL, source_url = NULL, page_source_id = NULL, source = 'local' WHERE source = 'copevents'"
  end

  def self.down
  end
end
