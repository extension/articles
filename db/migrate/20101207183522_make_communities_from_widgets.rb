class MakeCommunitiesFromWidgets < ActiveRecord::Migration
  def self.up
    
    # inactive flag for communities
    add_column(:communities,:active,:boolean,:default => 1)
    execute "UPDATE communities SET active = 1"
    Community.reset_column_information
          
    # we have two widgets (Thynka Little, #630 and #631) in the current data that are named the same - need to correct that before updating
    execute "UPDATE widgets SET name = CONCAT(name,'_2') where id = 631"
    
    # going to be slow - but it's necessary - probably need to deploy at a low usage hour
    # go through all the widgets and create a community for each and add the assignees
    Widget.all.each do |widget|
      widget.community = Community.create(:name => "Widget: #{widget.name}",:entrytype => Community::WIDGET, :memberfilter => Community::OPEN, :created_by => User.systemuserid, :active => widget.active)
      widget.save

      assignees = widget.role_based_assignees
      if(assignees.blank?)
        # add creator to leadership
        widget.community.add_user_to_leadership(widget.creator,User.systemuser,false)
      else
        # add members
        widget.community.mass_connect_as_member(assignees,User.systemuser,false)
        # add first assignee as leader
        widget.community.add_user_to_leadership(assignees[0],User.systemuser,false)
      end
    end  
  end

  def self.down
  end
end
