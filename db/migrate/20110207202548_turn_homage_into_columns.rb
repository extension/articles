class TurnHomageIntoColumns < ActiveRecord::Migration
  def self.up
    add_column(:communities,:homage_name,:string)
    add_column(:communities,:homage_id,:integer)
    
    Community.reset_column_information
    
    # get the publishing communities
    communitylist = Community.all(:conditions => ["entrytype = #{Community::APPROVED} or (entrytype = #{Community::USERCONTRIBUTED} and show_in_public_list = 1)"], :order => 'name')

    # loop through and get the current homage articles, if they exist
    current_homage_articles = {}
    communitylist.each do |community|
      if(primary_tag_name = community.primary_tag_name)
        current_homage_articles[community] = Article.bucketed_as('homage').tagged_with(primary_tag_name).ordered.first
      end
    end

    homage_bucket = ContentBucket.find_by_name('homage')

    current_homage_articles.each do |community, current_homage|
      if(current_homage)
        if(new_homage = current_homage.content_links[0].content)
          # make new item an homage
          homage_bucket.bucketables << new_homage
          # delete existing homage
          homage_bucket.bucketables.delete(current_homage)
          # update the community
          community.update_attributes(:homage_name => community.public_name, :homage_id => new_homage.id)
        elsif(community.id == 363) # special case for Plant Breeding & Genomics
          new_homage = Article.find_by_id(32362)
          puts "#{community.name} : current #{new_homage.title}"

          # make new item an homage
          homage_bucket.bucketables << new_homage
          # delete existing homage
          homage_bucket.bucketables.delete(current_homage)
          # update the community
          community.update_attributes(:homage_name => community.public_name, :homage_id => new_homage.id)
        end
      end
    end
  end

  def self.down
  end
end
