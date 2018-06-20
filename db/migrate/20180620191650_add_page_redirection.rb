class AddPageRedirection < ActiveRecord::Migration
  def change
    add_column(:pages, :redirect_page, :boolean, :default => false)
    add_column(:pages, :redirect_url, :text)
  end
end
