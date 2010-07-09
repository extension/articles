module LearnHelper
  
  def get_learn_connections  
    if @learn_session 
      presenter_connections = @learn_session.learn_connections
      if presenter_connections.length > 0
        presenters_to_return = presenter_connections.find_all{|conn| conn.connectiontype == LearnConnection::PRESENTER}
        if presenters_to_return.length > 0
          return presenters_to_return
        else
          return nil
        end
      else
        return nil
      end
    else
      return nil
    end
  end
  
  def get_users_from_connections(learn_connections)
    return learn_connections.collect{|lconn| User.find_by_id(lconn.user_id)}
  end
  
end
