class AddQuestionWranglerFlagToUser < ActiveRecord::Migration
  def self.up
    add_column(:users, :is_question_wrangler, :boolean, :default => false)
    User.reset_column_information
    qw_community = Community.find_by_id(Community::QUESTION_WRANGLERS_COMMUNITY_ID)
    qw_community.joined.each do |user|
      user.update_attribute(:is_question_wrangler, true)
    end
  end

  def self.down
  end
end
