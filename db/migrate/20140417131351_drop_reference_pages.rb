class DropReferencePages < ActiveRecord::Migration
  def change
    remove_column :pages, :reference_pages
  end
end
