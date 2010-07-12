# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::AdminController < ApplicationController
  before_filter :login_required
  before_filter :check_purgatory
  skip_before_filter :unescape_params
  
  layout 'aae'
  
  def index
  end
  
  def roles
    @role = Role.find_by_name(Role::ADMINISTRATOR)
  end
  
  def role
    @role = Role.find_by_id(params[:id])
    
    if !@role
      flash[:failure] = "No such role."
      redirect_to :action => 'index'
    end
  end
  
  def assign_role
    user = User.find_by_login(params[:user])
    role = Role.find_by_id(params[:role])

    if !role
      flash[:failure] = "No such role."
      redirect_to :action => 'roles'
      return
    end

    if !user
      flash[:failure] = "No such user."
      redirect_to :action => 'role', :id => role
      return
    end    
        
    if user.user_roles.detect { |ur| ur.role == role }
      flash[:failure] = user.fullname + " is already assigned to this role."
      redirect_to :action => 'role', :id => role
      return
    end
    
    user_role = UserRole.new
    user_role.user = user
    user_role.role = role

    if user_role.save
      flash[:success] = "Role assigned to #{user.fullname}"
      redirect_to :action => 'role', :id => role
    else
      flash[:failure] = "Failed to assign role to #{user.fullname}."
      redirect_to :action => 'role', :id => role
    end
  end
  
  def delete_assignment
    if !params[:id] or !(user_role = UserRole.find_by_id(params[:id]))
      flash[:failure] = "Invalid user role."
      redirect_to :action => 'roles'
      return
    end
        
    role = user_role.role
    user = user_role.user
    
    user_role.destroy
  
    flash[:success] = user.fullname + " no longer assigned to the " + role.name + " role."
    
    #if you revoke your own admin privileges
    if @currentuser.id == user.id
      redirect_to incoming_url
    else
      redirect_to :action => 'role', :id => role
    end
  end

  def add_category
    if !request.post?
      @category = Category.new
    else
      @category = Category.new(params[:category])
      
      if @category.save
        flash[:success] = "Category '#{@category.name}' created."
        redirect_to :action => "categories"
      end
    end    
  end

  def category
    @category = Category.find_by_id(params[:id])
    redirect_to :action => :categories unless @category
  end
  
  def add_subcategory
    @parent_category = Category.find_by_id(params[:id]) if request.get?
    @parent_category = Category.find_by_id(params[:category][:parent_id]) if request.post?

    if !@parent_category
      flash[:failure] = "Invalid category."
      redirect_to :action => "categories"
      return
    end

    if @parent_category.parent
      flash[:failure] = "Subcategories are only allowed for root categories."
      redirect_to :action => "category", :id => @parent_category.parent
      return
    end
    
    if request.post?
      @category = Category.new(params[:category])
      
      if @parent_category.children.detect { |cat| cat.name == @category.name }
        flash[:failure] = @parent_category.name + " already has a subcategory named " + @category.name + "."
        redirect_to :action => 'category', :id => @parent_category
        return
      end
      
      if @category.save
        flash[:success] = "New subcategory '" + @category.name + "' added to " + @category.parent.name + "."
        redirect_to :action => 'category', :id => @parent_category
      end
    else    
      @category = Category.new
      @category.parent = @parent_category
    end
  end
  
  def categories 
    @categories = Category.root_categories.all(:order => 'name')
  end
   
end