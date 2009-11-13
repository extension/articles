class AddInstitutionalMembersToInstitutions < ActiveRecord::Migration
  def self.up
    execute "UPDATE communities,communityconnections, (SELECT users.id as userid FROM `users` INNER JOIN `communityconnections` ON `users`.id = `communityconnections`.user_id WHERE ((`communityconnections`.community_id = 80) AND (communityconnections.connectiontype = 'member' OR communityconnections.connectiontype = 'leader'))) as users_to_update SET connectiontype = 'leader' WHERE communityconnections.community_id = communities.id and communityconnections.user_id = users_to_update.userid AND communities.entrytype = #{Community::INSTITUTION}"
  end

  def self.down
  end
end
