class CleanupDupFaqs < ActiveRecord::Migration
  def self.up
    # cleanup duplicate faqs - doing it this way so that the
    # dependent records are cleaned up as well, tags, links, etc.
    dup_select_sql = "SELECT pages.id from pages, (select source_id, min(created_at) as earliest_create_date, count(*) as dup_count from pages where source='copfaq' group by source_id having dup_count >= 2) as dups where pages.source_id = dups.source_id and pages.created_at = dups.earliest_create_date"
    rows = Page.connection.select_rows(dup_select_sql)
    # rows is an array of arrays with the single id value in it from the select
    pagelist = Page.where("id IN (#{rows.map{|id_array| id_array[0].to_i}.join(',')})")
    pagelist.each do |page|
      page.destroy
    end
    
    # now, fix the source_url issues since we've deleted the dups.
    execute("UPDATE pages set source_url = source_id, source_url_fingerprint = SHA1(source_id) where source = 'copfaq' and source_id != source_url")
  end

  def self.down
  end
end
