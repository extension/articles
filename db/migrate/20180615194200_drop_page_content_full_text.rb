class DropPageContentFullText < ActiveRecord::Migration
  def up
    remove_index(:pages,  :name => "title_content_full_index")
    execute "ALTER TABLE `pages` ENGINE = 'InnoDB'"
  end
end
