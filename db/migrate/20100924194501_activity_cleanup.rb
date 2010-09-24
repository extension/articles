class ActivityCleanup < ActiveRecord::Migration
  def self.up
    ActivityApplication.find_by_shortname('faq').update_attribute(:activitysource, "prod_dega")
    ActivityApplication.find_by_shortname('events').update_attribute(:activitysource, "prod_dega")
    ActivityApplication.find_by_shortname('aboutwiki').update_attribute(:activitysource, "prod_aboutwiki")
    ActivityApplication.find_by_shortname('collabwiki').update_attribute(:activitysource, "prod_collabwiki")
    ActivityApplication.find_by_shortname('copwiki').update_attribute(:activitysource, "prod_copwiki")
    ActivityApplication.find_by_shortname('docswiki').update_attribute(:isactivesource, false)
    justcode = ActivityApplication.find_by_shortname('justcode')
    justcode.update_attributes({:activitysource => '', :activitysourcetype => ActivityApplication::LOGINONLY})
    
    # clear out non-login activities for justcode
    execute "DELETE FROM activities WHERE activity_application_id = #{justcode.id} and activitycode != #{Activity::LOGIN_OPENID}"
    # clear out issues and changesets for justcode
    execute "DELETE FROM activity_objects WHERE activity_application_id = #{justcode.id}"  
  end

  def self.down
  end
end
