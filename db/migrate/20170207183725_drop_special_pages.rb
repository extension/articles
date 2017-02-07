class DropSpecialPages < ActiveRecord::Migration
  def up
    drop_table(:special_pages)
    remove_column(:pages, :is_special_page)
  end

end
