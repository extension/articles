module LearnHelper
  
  def get_learn_connections  
    if @learn_session 
      # if the learn session has not been saved to the db yet 
      if @learn_session.new_record?
        learn_connections = @learn_session.learn_connections
        if learn_connections.length > 0
          presenters_to_return = learn_connections.find_all{|conn| conn.connectiontype == LearnConnection::PRESENTER}
        else
          return nil
        end
      # otherwise, this is an existing record in the db
      else
        # first get current presenters in object. could be that there is an existing record, 
        # an edit has occured, and then a user error occured causing
        # the form to have to reload and we take a look at the learn connections associated with the object 
        # and compare them to the learn connections saved in the db. if they are the same, then we use either 
        # to get the learn connections. otherwise, we use what's stored in the object. 
        learn_connections = @learn_session.learn_connections
        if learn_connections.length > 0
          learn_session_object_presenters = learn_connections.find_all{|conn| conn.connectiontype == LearnConnection::PRESENTER}
          saved_presenters = @learn_session.learn_connections.find(:all, :conditions => {:connectiontype => LearnConnection::PRESENTER})
          
          # get the difference of the arrays to determine whether they have the same learn_session objects in them 
          if (learn_session_object_presenters - saved_presenters) == []
            presenters_to_return = saved_presenters
          # otherwise, we're using the newest (un-saved) learn_session objects
          else
            presenters_to_return = learn_session_object_presenters
          end 
        else
          return nil
        end
      end  
    
      if presenters_to_return.length > 0
        return presenters_to_return
      else
        return nil
      end
    # no learn session exists  
    else
      return nil
    end
  end
  
  def get_users_from_connections(learn_connections)
    return learn_connections.collect{|lconn| User.find_by_id(lconn.user_id)}
  end
  
  # designed to return tags for unsaved learn sessions via params (on create) or 
  # to return tags for saved learn sessions (on edit)
  # non-saved learn_sessions do not have tags as tags are applied after the learn_session is saved
  def get_tags_for_learn_session
    if params[:tags].blank?
      if @learn_session.tags.length > 0
        return @learn_session.tags.collect{|t| t.name}.join(Tag::JOINER)
      else
        return nil
      end
    else
      return params[:tags]
    end
  end
  
end
