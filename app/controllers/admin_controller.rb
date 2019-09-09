# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file
class AdminController < ApplicationController
  before_filter :admin_signin_required
  before_filter :turn_off_resource_areas
  before_filter :www_store_location

  layout 'frontporch'

  def index
    set_title("eXtension Pubsite Admin")
  end

  def shared_ownership
    set_title("Content with Shared Ownership")
    @pages = Page.has_multiple_community_tags()
    @total_pages = @pages.length
    render :layout => 'admin'
  end

  def manage_exports_and_redirects
    if params[:tag]
      @tag = params[:tag]
      @tagged_pages = Page.tagged_with(@tag)
    end
  end

  def batch_redirect_confirmation
    if request.post?
      tag = params[:tag]
      wordpress_domain = params[:wordpress_domain]

      if tag.blank?
        flash[:error] = 'A tag is required to contruct the new URLs'
        return redirect_to admin_manage_exports_and_redirects_url
      end

      if wordpress_domain.blank?
        flash[:error] = 'A domain is required to contruct the new URLs'
        return redirect_to admin_manage_exports_and_redirects_url(tag: tag)
      end

      begin
        uri = URI.parse(wordpress_domain)
        if(uri.class != URI::HTTP and uri.class != URI::HTTPS)
          flash[:error] = 'This domain URL must be http:// or https://'
          return redirect_to admin_manage_exports_and_redirects_url
        end
        if(uri.host.nil?)
          flash[:error] = 'This domain URL must be have a valid host.'
          return redirect_to admin_manage_exports_and_redirects_url
        end
        rescue URI::InvalidURIError
          flash[:error] = 'This domain URL is not a valid URL.'
          return redirect_to admin_manage_exports_and_redirects_url
      end

      @tag = tag
      @wordpress_domain = wordpress_domain
      #find all pages by tag
      @tagged_pages = Page.tagged_with(tag)
    else
      return redirect_to admin_manage_exports_and_redirects_url
    end #if request.post?
  end

  def batch_redirect_confirmation_eorganic
    if request.post?
      tag = params[:tag]

      if tag.blank?
        flash[:error] = 'A tag is required to contruct the new URLs'
        return redirect_to admin_manage_exports_and_redirects_url
      end

      @tag = tag
      @wordpress_domain = 'https://eorganic.org'
      #find all pages by tag
      @tagged_pages = Page.tagged_with(tag)
    else
      return redirect_to admin_manage_exports_and_redirects_url
    end #if request.post?
  end

  def batch_redirect
   if request.post?
     tag = params[:tag]
     wordpress_domain = params[:wordpress_domain]

     if tag.blank?
       flash[:error] = 'A tag is required to contruct the new URLs'
       return redirect_to admin_manage_exports_and_redirects_url
     end

     if wordpress_domain.blank?
       flash[:error] = 'A domain URL is required to contruct the new URLs'
       return redirect_to admin_manage_exports_and_redirects_url(tag: tag)
     end

     #find all pages by tag
     @tagged_pages = Page.tagged_with(tag)

     count = 0
     @tagged_pages.each do |page|
       new_url = wordpress_domain + '/' + page.make_wordpress_permalink_title
       single_page = Page.find(page.id)
       if(single_page.redirect(new_url,current_person))
         count += 1
       else
         error_messages += page.errors.full_messages.join("<br/>").html_safe
         flash[:error] = error_messages
         return redirect_to admin_manage_exports_and_redirects_url(tag: tag)
       end
     end
     flash[:success] = "All pages redirected"
     return redirect_to admin_manage_exports_and_redirects_url(tag: tag)
   end
 end

 def batch_redirect_eorganic
  if request.post?
    tag = params[:tag]

    if tag.blank?
      flash[:error] = 'A tag is required to contruct the new URLs'
      return redirect_to admin_manage_exports_and_redirects_url
    end

    #find all pages by tag
    @tagged_pages = Page.tagged_with(tag)

    count = 0
    @tagged_pages.each do |page|
      new_url = 'https://eorganic.org/pages/' + page.id.to_s + '/' + page.url_title
      single_page = Page.find(page.id)
      if(single_page.redirect(new_url,current_person))
        count += 1
      else
        error_messages += page.errors.full_messages.join("<br/>").html_safe
        flash[:error] = error_messages
        return redirect_to admin_manage_exports_and_redirects_url(tag: tag)
      end
    end
    flash[:success] = "All pages redirected"
    return redirect_to admin_manage_exports_and_redirects_url(tag: tag)
  end
end

  def manage_communities
    set_title("Manage Communities - Pubsite Admin")
    @communities =  PublishingCommunity.all(:order => 'name')
  end

  def manage_institution_logos
    set_title("Manage Institution Logos - Pubsite Admin")
    @institutionslist = BrandingInstitution.all(:order => 'name')
  end

  def manage_community_logos
    set_title("Manage Community Logos - Pubsite Admin")
    @communitieslist = PublishingCommunity.all(:order => 'name')
  end

  def edit_institution_logo
    @institution = BrandingInstitution.find_by_id(params[:id])
    if(@institution.nil?)
      flash[:error] = 'Invalid institution'
      redirect_to :action => :index
    end
    @logo = @institution.logo ||= Logo.new
    if(request.post? || request.put?)
      @newlogo = Logo.new(params[:logo])
      @newlogo.logotype = Logo::INSTITUTION
      if @newlogo.save
        @logo.destroy if !(@logo.nil?)
        @institution.update_attribute(:logo_id, @newlogo.id)
        flash[:notice] = 'Logo was successfully uploaded.'
        redirect_to(:action => 'manage_institution_logos')
      end
    end
  end

  def edit_community_logo
    @community = PublishingCommunity.find_by_id(params[:id])
    if(@community.nil?)
      flash[:error] = 'Invalid community'
      redirect_to :action => :index
    end
    @logo = @community.logo
    if(request.post?)
      @newlogo = Logo.new(params[:logo])
      @newlogo.logotype = Logo::COMMUNITY
      if @newlogo.save
        @logo.destroy if !(@logo.nil?)
        @community.update_attribute(:logo_id, @newlogo.id)
        flash[:notice] = 'Logo was successfully uploaded.'
        redirect_to(:action => 'manage_community_logos')
      end
    end
  end

  def delete_community_logo
    @community = PublishingCommunity.find_by_id(params[:id])
    if(@community.nil?)
      flash[:error] = 'Invalid community'
      redirect_to :action => :index
    end
    @community.logo.destroy
    flash[:notice] = 'Logo was successfully removed.'
    redirect_to(:action => 'manage_community_logos')
  end

  def delete_institution_logo
    @institution = BrandingInstitution.find_by_id(params[:id])
    if(@institution.nil?)
      flash[:error] = 'Invalid institution'
      redirect_to :action => :index
    end
    @institution.logo.destroy
    flash[:notice] = 'Logo was successfully removed.'
    redirect_to(:action => 'manage_institution_logos')
  end

  def manage_institutions
    set_title("Manage Institutions - Pubsite Admin")
    @landgrant_institutions =  BrandingInstitution.all(:include => :location, :order => 'locations.abbreviation')
  end

  def manage_locations_office_links
    set_title("Manage Office Links - Pubsite Admin")
    @locations =  Location.displaylist
  end

  def edit_location_office_link
    set_title('Edit Location Office Link')
    set_title("Edit Location Office Link - Pubsite Admin")
    @location = Location.find(params[:id])
  end

  def update_location_office_link
    @location =  Location.find(params['id'])
    oldlink = @location.office_link
    @location.office_link = params['location']['office_link']

    if @location.save
      AdminLog.log_event(current_person, AdminLog::UPDATE_LOCATION_OFFICE_LINK,{:location_id => @location.id, :location_name => @location.name, :oldlink => oldlink, :newlink => @location.office_link})
      flash[:notice] = 'Location Updated'
    else
      flash[:notice] = 'Error updating location'
    end
    redirect_to :action => :manage_locations_office_links

  end

  def update_public_community
    @community =  PublishingCommunity.find(params['id'])
    @community.public_description = params['community']['public_description']
    @community.public_name = params['community']['public_name']
    @community.is_launched = ( params['community']['is_launched'] ? true : false)
    @community.homage_name = params['community']['homage_name']
    @community.aae_group_id = params['community']['aae_group_id']
    @community.twitter_handle = params['community']['twitter_handle']
    @community.facebook_handle = params['community']['facebook_handle']
    @community.youtube_handle = params['community']['youtube_handle']
    @community.pinterest_handle = params['community']['pinterest_handle']
    @community.gplus_handle = params['community']['gplus_handle']
    @community.twitter_widget = params['community']['twitter_widget']
    @community.migrated_domain = params['community']['migrated_domain']

    # sanity check tags
    if(params['community']['tag_names'].blank?)
      flash[:notice] = "You must specify a resource area tag for publishing communities"
      return(render(:action => "edit_public_community"))
    end

    # sanity check tag names
    this_community_tags = @community.tags
    other_community_tags = Tag.community_tags - this_community_tags
    other_community_tag_names = other_community_tags.map(&:name)
    updatelist = Tag.castlist_to_array(params['community']['tag_names'],true)
    invalid_tags = []
    updatelist.each do |tagname|
      if(other_community_tag_names.include?(tagname) or Tag::CONTENTBLACKLIST.include?(tagname))
        invalid_tags << tagname
      end
    end

    if(!invalid_tags.blank?)
      flash[:notice] = "The following tag names are in use by other communities or are not allowed for community use: #{invalid_tags.join(Tag::JOINER)}"
      return(render(:action => "edit_public_community"))
    end

    if @community.save
      flash[:notice] = 'Community Updated'
      @community.tag_names=(params['community']['tag_names'])
      # update create resource tags
      @community.update_create_group_resource_tags
      AdminLog.log_event(current_person, AdminLog::UPDATE_PUBLIC_COMMUNITY,{:community_id => @community.id, :community_name => @community.name})
      redirect_to :action => :manage_communities
    else
      flash[:notice] = 'Error updating community'
      return(render(:action => "edit_public_community"))
    end
  end

  def edit_public_community
    set_title('Edit Community Public Options')
    set_title("Edit Community - Pubsite Admin")
    @community = PublishingCommunity.find(params[:id])
  end

  def update_public_institution
    @institution =  BrandingInstitution.find(params['id'])
    @institution.name = params['institution']['name']
    @institution.referer_domain = params['institution']['referer_domain']
    @institution.public_uri = params['institution']['public_uri']
    @institution.is_active = params['institution']['is_active']

    if @institution.save
      flash[:notice] = 'Institution Updated'
      AdminLog.log_event(current_person, AdminLog::UPDATE_PUBLIC_INSTITUTION,{:institution_id => @institution.id, :institution_name => @institution.name})

    else
      flash[:notice] = 'Error updating institution'
    end
    redirect_to :action => :manage_institutions
  end

  def edit_public_institution
    set_title('Edit Institution Public Options')
    set_title("Edit Institution - Pubsite Admin")
    @institution = BrandingInstitution.find(params[:id])
  end

  def category_tag_redirects
  end

  def page_redirects
  end

end
