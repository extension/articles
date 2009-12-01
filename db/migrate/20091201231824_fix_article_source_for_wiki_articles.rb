class FixArticleSourceForWikiArticles < ActiveRecord::Migration
  def self.up
	# replaces 'www.extension.org/pages' with 'cop.extension.org/wiki' to allow for linking to the source article for 
	# preview articles and more - will match wiki feed output for the original url of the article
	execute "UPDATE articles set original_url = REPLACE(original_url,'www.extension.org/pages','cop.extension.org/wiki')"
  end

  def self.down
  end
end
