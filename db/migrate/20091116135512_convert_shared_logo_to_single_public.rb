class ConvertSharedLogoToSinglePublic < ActiveRecord::Migration
  def self.up
    # the following institutions are set to "shared logo"
    # what we are going to do is just have a condition where
    # *one* institution from the location is set to "public" - so
    # that we don't have to build interfaces that will
    # make it so an institution can be marked "shared logo"
    # University of Delaware
    # Delaware State University
    # Kentucky State University
    # University of Kentucky
    # North Carolina A & T State University
    # North Carolina State University
    # Cooperative Extension Program at Prairie View
    # Texas AgriLife Extension Service
  
    unmark_public_list = []
    unmark_public_list << 'Delaware State University'
    unmark_public_list << 'Kentucky State University'
    unmark_public_list << 'North Carolina A & T State University'
    unmark_public_list << 'Cooperative Extension Program at Prairie View'
    
    unmark_public_list.each do |iname|
      execute "UPDATE communities SET communities.show_in_public_list = 0 WHERE communities.name = '#{iname}'"
    end
    
    remove_column(:communities, :shared_logo)
      
  end

  def self.down
  end
end
