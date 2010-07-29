# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Feed < ActiveRecord::Base
  
  # TODO: mapping of column names to gdata params
  # TODO: defaults per param
  # TODO: named_scopes for creating lists
  def to_atom_feed(opts={})
    
    feed_params = {
      :start_index_default => 1,
      :max_results_default => 50,
      :updated_min_default => Time.utc(2006,10),
      :updated_max_default => Time.utc(Time.now.year + 5, Time.now.month),
      :published_min_default => Time.utc(2006,10),
      :published_max_default => Time.utc(Time.now.year + 5, Time.now.month),
      :updated_col_name => "updated_at",
      :published_col_name => "created_at"
    }
    
    feed_params.merge!(opts)
    @filteredparams = FilterParams.new(params)
    
    start_index = @filteredparams.start_index || 1
    max_results = @filteredparams.max_results || 50
    q = nil
    author = nil
    alt = nil
    
    # eX content did not exist in published fashion prior to 10/2006.
    updated_min = @filteredparams.updated_min || feed_params[:updated_min_default]
    updated_max = @filteredparams.updated_max || feed_params[:updated_max_default]
    published_min = @filteredparams.published_min || feed_params[:published_min_default]
    published_max = @filteredparams.published_max || feed_params[:published_max_default]
    category_array = nil
    
    if params[:content_tags] && params[:content_tags].length > 0
      category_array = params[:content_tags]
      if category_array.length > 3
        raise ArgumentError
      end
    end
    
    entries, total_possible_results = get_entries(type, category_array, updated_min, 
          updated_max, published_min, published_max, start_index, max_results)  
    end
    
    
    updated = entries.first.nil? ? Time.now.utc : entries.first.updated_at
    
    feed_meta = {:title => @feed_title, 
                 :subtitle => "eXtension published content",
                 :url => url_for(:only_path => false),
                 :alt_url => url_for(:only_path => false, :controller => 'main', :action => 'index'),
                 :total_results => total_possible_results.to_s,
                 :start_index => start_index.to_s,
                 :items_per_page => max_results.to_s,
                 :updated_at => updated}
    render_atom_feed_from(entries, feed_meta)
  
  end

end
