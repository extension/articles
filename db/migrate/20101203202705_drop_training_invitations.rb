class DropTrainingInvitations < ActiveRecord::Migration
  def self.up
    drop_table "training_invitations"
  end

  def self.down
  end
end
