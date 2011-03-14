class ModifyDailyNumbersForContentMerge < ActiveRecord::Migration
  def self.up
    execute "UPDATE daily_numbers SET datasource_type = 'Page' where datasource_type IN ('Article','Faq','Event')"
  end

  def self.down
  end
end
