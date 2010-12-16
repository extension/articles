class ModifyDailyNumbers < ActiveRecord::Migration
  def self.up
    # modify string lengths
    execute "ALTER TABLE `daily_numbers` CHANGE COLUMN `datasource_type` `datasource_type` VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL;"
    execute "ALTER TABLE `daily_numbers` CHANGE COLUMN `datatype` `datatype` VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL DEFAULT NULL;"
    # add an index
    add_index('daily_numbers',['datasource_id','datasource_type','datadate','datatype'],:name => 'dn_index')
    
    # update daily numbers articles/news counts
    execute "UPDATE daily_numbers,(select datasource_id as news_id,datasource_type as news_type, datadate as newsdate,total as newstotal,thatday as newsthatday from daily_numbers where datatype = 'published news' and DATE(updated_at) < '2010-12-15') as newsnumbers SET total = total-newstotal, thatday = thatday - newsthatday WHERE datatype = 'published articles' and datasource_id = news_id and datasource_type = news_type and datadate = newsdate;"
    
    execute "UPDATE daily_numbers,(select datasource_id as news_id,datasource_type as news_type, datadate as newsdate,total as newstotal,thatday as newsthatday from daily_numbers where datatype = 'published news' and datadate = '2010-12-14') as newsnumbers SET total = total-newstotal, thatday = thatday - newsthatday WHERE datatype = 'published articles' and datasource_id = news_id and datasource_type = news_type and datadate = newsdate;"
    
    
  end

  def self.down
  end
end
