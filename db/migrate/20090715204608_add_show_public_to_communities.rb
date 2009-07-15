class AddShowPublicToCommunities < ActiveRecord::Migration
  def self.up
    add_column(:communities, 'show_in_public_list', :boolean, :default => false)
    # set to true for CoP's
    execute "UPDATE `communities` SET show_in_public_list = 1 WHERE entrytype = #{Community::APPROVED}"
  end

  def self.down
    remove_column(:communities, 'show_in_public_list' )
  end
end
