class AddContentLinksIndex < ActiveRecord::Migration
  def self.up
    add_index(:content_links,['content_id','content_type','status','linktype'], :name => "coreindex")
  end

  def self.down
  end
end
