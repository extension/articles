class CleanupRatings < ActiveRecord::Migration
  def self.up
    # no need to drop ratings table, we will not dump it over from the pubsite data
    remove_column(:articles,:average_ranking)
    remove_column(:faqs,:average_ranking)
    # events have no ratings
  end

  def self.down
  end
end
