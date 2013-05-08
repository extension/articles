# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file
module AuthLib

  def current_person
    if(!@current_person)
      if(session[:person_id])
        @current_person = Person.find_by_id(session[:person_id])
      end
    end
    @current_person
  end
  
  def set_current_person(person)
    if(person.blank?)
      @current_person = nil
      reset_session
    else
      @current_person = person
      session[:person_id] = person.id
    end
  end

  private  
  

  def signin_required
    if session[:person_id]      
      person = Person.find_by_id(session[:person_id])
      if (person.signin_allowed?)
        set_current_person(person)
        return true
      else
        set_current_person(nil)
        return redirect_to(root_url)
      end        
    end

    # store current location so that we can 
    # come back after the user logged in
    www_store_location
    www_access_denied
    return false 
  end
  
  
  def signin_optional
    if session[:person_id]      
      person = Person.find_by_id(session[:person_id])
      if (person.signin_allowed?)
        set_current_person(person)
      end
    end
    return true
  end

  def www_access_denied
    redirect_to(:controller=>:auth, :action => :people)
  end  
  
  
  # store current uri in  the session.
  # we can return to this location by calling return_location
  def www_store_location
    session[:www_return_to] = request.fullpath
  end
  
  def www_clear_location
    session[:www_return_to] = nil
  end

  # move to the last store_location call or to the passed default one
  def www_redirect_back_or_default(default)
    if session[:www_return_to].nil?
      redirect_to default
    else
      redirect_to session[:www_return_to]
      session[:www_return_to] = nil
    end
  end


  def admin_signin_required
    if session[:person_id]      
      person = Person.find_by_id(session[:person_id])
      if (person.signin_allowed? and person.is_admin?)
        set_current_person(person)
        return true
      else
        set_current_person(nil)
        return redirect_to(:controller => 'notice', :action => 'admin_required')
      end
    end

    # store current location so that we can 
    # come back after the user logged in
    www_store_location
    www_access_denied
    return false 
  end

end
