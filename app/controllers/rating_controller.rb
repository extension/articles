class RatingController < ApplicationController

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :add_rating ], :redirect_to => {:action => :list}

  def show
    @object = get_thread_object(params[:object][:class],params[:object][:id])
    if (@object.nil?)
      # this is completely weird, but I want to prevent a crash, the odds of this occurring are low, and would
      # have to be done by spammer script or whatever that are picking object types outside our allowed rateable types.
      return render(:text => "No Ratings.")
    end
    @rating = @object.rating
    #@thread_post_pages, @thread_posts = paginate :thread_posts, :per_page => 10, :order => 'root_id asc, lft'
    render :partial => '/shared/rating',  :locals => { :object => @object, :new_ranking => false }
  end

  def add_rating
    @object = get_thread_object(params[:object][:class],params[:object][:id])
    if (@object.nil?)
       # this is completely weird, but I want to prevent a crash, the odds of this occurring are low, and would
       # have to be done by spammer script or whatever that are picking object types outside our allowed rateable types.
       return render(:text => "No Ratings.")
    end
    
    @object.add_rating Rating.new(:rating => params[:rating].to_i )
    @object.average_ranking = @object.rating
    @object.save
    render :partial => '/shared/rating',  :locals => { :object => @object, :new_ranking => true }
  end
  
  protected
  def get_thread_object(klass,id)
    return nil if klass.nil?
    return nil if id.nil?
    
    case klass.downcase
    when "article"
      findklass = "Article"
    when "faq"
      findklass = "Faq"
    else
      return nil
    end
    
    object = Object.const_get(findklass).find(id)
    
    return object
  end  
end
