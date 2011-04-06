# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class LinkStat < ActiveRecord::Base
  belongs_to :page
  
  
  # mass update of the link stats
  def self.update_counts
      
    # total counts
    total_counts = Link.includes(:linkedpages).group("pages.id").count
    
    # external counts
    external_counts = Link.external.includes(:linkedpages).group("pages.id").count
    
    # internal counts
    internal_counts = Link.internal.includes(:linkedpages).group("pages.id").count
    
    # local counts
    local_counts = Link.local.includes(:linkedpages).group("pages.id").count
        
    # wanted counts
    wanted_counts = Link.unpublished.includes(:linkedpages).group("pages.id").count

    # broken counts
    broken_counts = Link.broken.includes(:linkedpages).group("pages.id").count
    
    # warning counts
    warning_counts = Link.warning.includes(:linkedpages).group("pages.id").count
    
    # redirect counts
    redirect_counts = Link.redirected.includes(:linkedpages).group("pages.id").count
  
    # pages
    Page.all.each do |page|
      linkcounts = {:total => 0, :external => 0,:local => 0, :wanted => 0, :internal => 0, :broken => 0, :redirected => 0, :warning => 0}
      linkcounts[:total] = total_counts[page.id]  if(total_counts[page.id])
      linkcounts[:external] = external_counts[page.id]  if(external_counts[page.id])
      linkcounts[:local] = local_counts[page.id]  if(local_counts[page.id])
      linkcounts[:wanted] = wanted_counts[page.id]  if(wanted_counts[page.id])
      linkcounts[:internal] = internal_counts[page.id]  if(internal_counts[page.id])
      linkcounts[:broken] = broken_counts[page.id]  if(broken_counts[page.id])
      linkcounts[:redirected] = redirect_counts[page.id]  if(redirect_counts[page.id])
      linkcounts[:warning] = warning_counts[page.id]  if(warning_counts[page.id])

      if(page.link_stat.nil?)
        page.create_link_stat(linkcounts)
      else
        page.link_stat.update_attributes(linkcounts)
      end
    end

  end
  
  
end