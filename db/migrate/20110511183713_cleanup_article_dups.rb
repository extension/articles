class CleanupArticleDups < ActiveRecord::Migration
  def self.up
    # cleanup duplicate articles - doing it this way so that the
    # dependent records are cleaned up as well, tags, links, etc.
    dup_select_sql = "SELECT pages.id from pages, (select title, min(id) as earliest_create_id, count(*) as dup_count from pages where (page_source_id = 1 or page_source_id = 6) group by title having dup_count >= 2) as dups where pages.title = dups.title and pages.id = dups.earliest_create_id"
    rows = Page.connection.select_rows(dup_select_sql)
    # rows is an array of arrays with the single id value in it from the select
    pagelist = Page.where("id IN (#{rows.map{|id_array| id_array[0].to_i}.join(',')})")
    pagelist.each do |page|
      page.destroy
    end
    
    # fix references to create
    execute("UPDATE pages SET source='create' where page_source_id = 6")
    
  end

  def self.down
  end
end
