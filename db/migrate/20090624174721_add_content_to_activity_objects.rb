class AddContentToActivityObjects < ActiveRecord::Migration
  def self.up
    # this makes me a little nervous, but it's the quickest path right now to dealing with this search and content issue
    execute "ALTER TABLE `activity_objects`  ENGINE = MYISAM"
    # add content column
    execute "ALTER TABLE `activity_objects` ADD `content` MEDIUMTEXT NULL AFTER `fulltitle`"  
    # add foreignrevision
    execute "ALTER TABLE `activity_objects` ADD `foreignrevision` INT NULL DEFAULT '0' AFTER `foreignid`"
    # index
    execute "ALTER TABLE `activity_objects` ADD FULLTEXT `title_content_full_index` (`fulltitle`,`content`)"
  end

  def self.down
  end
end
