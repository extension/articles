class AddLinkFlagsToArticles < ActiveRecord::Migration
  def self.up
    add_column(:articles,:has_broken_links,:boolean)
  end

  def self.down
  end
end
