class ChangeLinkFields < ActiveRecord::Migration
  def up
    change_column(:links, :path, :text)
  end
end
