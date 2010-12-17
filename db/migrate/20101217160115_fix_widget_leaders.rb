class FixWidgetLeaders < ActiveRecord::Migration
  def self.up
    # going to be slow - but it's necessary - probably need to deploy at a low usage hour
    # go through all the widgets and create a community for each and add the assignees
    Widget.all.each do |widget|
      widget.touch # creates community
      
      # need to pick the vacationers back up
      all_assignees = widget.role_based_assignees
      vacation_assignees = widget.role_based_assignees.all(:conditions => 'accounts.aae_responder = 0')
      if(!vacation_assignees.blank?)
        # add members
        widget.community.mass_connect_as_member(vacation_assignees,User.systemuser,false)
      end
      
      # fix leadership issue.
      if(widget.community.leaders.count > 1 and widget.community.leaders.include?(widget.creator))
        # more than one leader?
        if(!all_assignees.blank? and (all_assignees.first !=  widget.creator))
          widget.community.remove_user_from_membership(widget.creator,User.systemuser,false)
        end
      end
    end
  end

  def self.down
  end
end
