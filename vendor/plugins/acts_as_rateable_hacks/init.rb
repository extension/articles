Rating.class_eval do
  # we're reaching into the Rating model and adding support for recording the parent title
  # pursuant to Feature #14
  
  before_save :record_rateable_title
  
  def record_rateable_title
    parent = eval("#{self.rateable_type}.find(#{self.rateable_id})")
    self.rateable_title = parent.title unless parent.nil?
  rescue ActiveRecord::RecordNotFound
    self.rateable_id = 0
  end
  
  # Allow ratings to find their rateable parents
  
  def self.relink_all
    flag = true
    
    self.find(:all).each do |rating|
      case rating.rateable_type
        when 'Article'
          parent = Article.find_by_title(rating.rateable_title)
        when 'Faq'
          parent = Faq.find_by_question(rating.rateable_title)
        else # not sure how we got here - treat it as a wiki page
          parent = Article.find_by_title(rating.rateable_title)
      end
      
      if parent
        p "*** Adding rating #{rating.id} to #{parent.class.to_s} #{parent.id}"
        parent.ratings << rating 
      else
        p "*** could not find parent for rating #{rating.id}"
        rating.update_attribute(:rateable_id, 0)
      end
      flag &&= parent
    end
    (flag && true)
  end
end