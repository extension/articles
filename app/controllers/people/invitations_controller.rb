# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
require 'hpricot'

class People::InvitationsController < ApplicationController
  layout 'people'
  before_filter :login_required
  before_filter :check_purgatory
   
  
  def index
    show = params[:show].nil? ? 'pending' : params[:show]
    case show
    when 'all'
      @invitelist = Invitation.paginate(:all, :include => [:user,:colleague], :order => 'created_at desc',:page => params[:page])
      @page_title = "All Invitations"
    when 'accepted'
      @invitelist = Invitation.accepted.paginate(:all, :order => 'created_at desc',:page => params[:page])
      @page_title = "Accepted Invitations"
    when 'completed'
      @invitelist = Invitation.completed.paginate(:all, :order => 'created_at desc',:page => params[:page])
      @page_title = "Completed Invitations"
    when 'invalidemail'
      @invitelist = Invitation.invalidemail.paginate(:all, :order => 'created_at desc',:page => params[:page])
      @page_title = "Invalid Invitations"
    when 'pending'
      @invitelist = Invitation.pending.paginate(:all, :order => 'created_at desc',:page => params[:page])
      @page_title = "Pending Invitations"
    else
      @invitelist = Invitation.pending.paginate(:all, :order => 'created_at desc',:page => params[:page])
      @page_title = "Pending Invitations"
    end
  end
  
  def mine
    show = params[:show].nil? ? 'pending' : params[:show]
    case show
    when 'all'
      @invitelist = Invitation.byuser(@currentuser).paginate(:all, :order => 'created_at desc',:page => params[:page])
      @page_title = "All Invitations"
    when 'accepted'
      @invitelist = Invitation.byuser(@currentuser).accepted.paginate(:all, :order => 'created_at desc',:page => params[:page])
      @page_title = "Accepted Invitations"
    when 'completed'
      @invitelist = Invitation.byuser(@currentuser).completed.paginate(:all, :order => 'created_at desc',:page => params[:page])
      @page_title = "Completed Invitations"
    when 'invalidemail'
      @invitelist = Invitation.byuser(@currentuser).invalidemail.paginate(:all, :order => 'created_at desc',:page => params[:page])
      @page_title = "Invalid Invitations"
    when 'pending'
      @invitelist = Invitation.byuser(@currentuser).pending.paginate(:all, :order => 'created_at desc',:page => params[:page])
      @page_title = "Pending Invitations"
    else
      @invitelist = Invitation.byuser(@currentuser).pending.paginate(:all, :order => 'created_at desc',:page => params[:page])
      @page_title = "Pending Invitations"
    end
  end
  
  def new
    @invitation = Invitation.new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create  
    creationoptions = {:user => @currentuser, :email => params[:invitation][:email], :message => params[:invitation][:message]}
    if(!params[:invitecommunities].nil?)
      creationoptions[:additionaldata] = {:invitecommunities => params[:invitecommunities]}
    end
    @invitation = Invitation.new(creationoptions)
    
    # check for existing user with same email
    if(@showuser = User.find_by_email(params[:invitation][:email]))
      flash.now[:warning] = "#{link_to_user(@showuser)} already has an eXtensionID"
      return render(:action => "new")
    end
    
    # check for existing invitation
    if(@existinginvitation = Invitation.find_by_email(params[:invitation][:email]))
      if(@existinginvitation.user == @currentuser)
        warningmsg = "You have already invited #{@existinginvitation.email} to get an eXtensionID."
        warningmsg += " <a href='#{edit_people_invitation_url(@existinginvitation)}'>Resend invitation?</a>"
      else
        warningmsg = "#{@existinginvitation.email} has already been invited to get an eXtensionID by #{link_to_user(@existinginvitation.user)}."
      end
      flash.now[:warning] = warningmsg
      return render(:action => "new")
    end
    
    if(!@invitation.save)
      return render(:action => "new")
    end
  end
  
  def show
    @invitation = Invitation.find_by_id(params[:id])
    if(@invitation.nil?)  
      flash[:error] = 'That invitation does not exist'  
      return(redirect_to(:action => 'index'))
    end
  end 
  
  def edit
    @invitation = Invitation.find_by_id(params[:id])
    if(@invitation.status == Invitation::ACCEPTED)
      flash[:warning] = 'This invitation has already been accepted.'
      return(redirect_to(people_invitation_url(@invitation)))
    end
  end
  
  def update
    @invitation = Invitation.find_by_id(params[:id])
    if(@invitation.nil?)  
      flash[:error] = 'That invitation does not exist'  
      return(redirect_to(:action => 'index'))
    end
    updateoptions = {}
    # only allow updates of what we only allow
    if(@invitation.status == Invitation::INVALID_EMAIL)
      # expecting email change
      if(params[:invitation][:email].blank? or (params[:invitation][:email] == @invitation.email))
        flash.now[:warning] = 'This email address was marked as invalid, please change the invitation email.'
        return(render(:action => 'edit'))
      else
        updateoptions[:email] = params[:invitation][:email]
        updateoptions[:status] = Invitation::PENDING
      end
    end
    
    if(@invitation.user != @currentuser)
      # only accept a resendmessage
      if(!params[:invitation][:resendmessage].blank?)
        updateoptions[:resendmessage] = params[:invitation][:resendmessage]
      end
    else
      if(!params[:invitation][:message].blank?)
        updateoptions[:message] = params[:invitation][:message]
      else
        updateoptions[:message] = ''
      end
      
      if(!params[:invitecommunities].nil?)
        if(@invitation.additionaldata.blank?)
          updateoptions[:additionaldata] = {:invitecommunities => params[:invitecommunities]}
        else
          updateoptions[:additionaldata] =  @invitation.additionaldata.merge(:invitecommunities => params[:invitecommunities])
        end
      end
    end
    
    if(!@invitation.update_attributes(updateoptions))
      return render(:action => "edit")
    else
      @invitation.resend(@currentuser)
    end
  end 
  
  private
  
  def link_to_user(user,opts = {})
    show_unknown = opts.delete(:show_unknown) || false
    show_systemuser = opts.delete(:show_systemuser) || false
    nolink = opts.delete(:nolink) || false
    
    if user.nil?
      show_unknown ? 'Unknown' : 'System'
    elsif(user.id == 1 and !show_systemuser)
      'System' 
    elsif(nolink)
      "#{user.fullname}"
    else
      "<a href='#{url_for(:controller => '/people/colleagues', :action => :showuser, :id => user.login)}'>#{user.fullname}</a>"
    end
  end
  
end
