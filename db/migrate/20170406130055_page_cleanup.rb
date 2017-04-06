class PageCleanup < ActiveRecord::Migration
  def up
    drop_table(:page_updates)
  end
end
