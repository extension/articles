# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::ReportsController < ApplicationController
    layout  'aae_reports_home'  
    before_filter :login_required
    before_filter :check_purgatory

     def index
       @locs = Location.find(:all, :order => "entrytype, name")
     end

    ##Activity Reports
    def activity
       @earliest_date = SubmittedQuestion.find_earliest_record.created_at.to_date
     	 @latest_date = Date.today
     	 @dateinterval = validate_datepicker({:earliest_date => @earliest_date, :default_datefrom => @earliest_date, :latest_date => @latest_date, :default_dateto => @latest_date})           
       @new= 0; @answ = 0; @resolved=0; @rej = 0; @noexprtse=0
       @rept = Aaereport.new(:name => "Activity")
       @cats = Category.find(:all, :order => 'name')
    end

     def state_activity
         @typelist = [];  @open={}; @resolved={}; @answered={}; @rejected={}; @no_expertise={} ; openquestions={}
             @earliest_date = SubmittedQuestion.find_earliest_record.created_at.to_date
          	 @latest_date = Date.today
          	 @dateinterval = validate_datepicker({:earliest_date => @earliest_date, :default_datefrom => @earliest_date, :latest_date => @latest_date, :default_dateto => @latest_date})

          @typelist  = Location.find(:all, :order => "entrytype, name")
          @rept = Aaereport.new({:name => "ActivityGroup", :filters => {:g => 'state', :dateinterval => @dateinterval}})
          openquestions = (@rept.NewQuestion({},[]))[0] 
 
          reslvd = (@rept.ResolvedQuestion({},[]))[0]
          answed = (@rept.ResolvedQuestion({ :status_state => SubmittedQuestion::STATUS_RESOLVED},[]))[0]
          rejectd = (@rept.ResolvedQuestion({ :status_state => SubmittedQuestion::STATUS_REJECTED},[]))[0]
          noexp = (@rept.ResolvedQuestion({:status_state => SubmittedQuestion::STATUS_NO_ANSWER},[]))[0]
            stuv = nil
             @typelist.each do |st|
                stuv = st.id
                @open[st.name]= openquestions[stuv]
                @resolved[st.name] = reslvd[stuv]
                @answered[st.name] = answed[stuv]
                @rejected[st.name] = rejectd[stuv]
                @no_expertise[st.name] = noexp[stuv]
              end
      end
      
      
  
    def activity_by_state
      # thoughts..
      # what does it mean if someone selects state and tags? a subdivision of states with category entries? or vice versa? How do we allow them to do the vice-versa?
      # obviously these are more complicated summary reports.  Or, could start with state, tags and then allow, on the
      # display screen under where they choose the date, to select 1 of something else that may exist (ie, communities), which would result in one entry on the next page for the combination
  
       state_activity
  
       	if(params[:sortorder] and params[:sortorder]=='d')
     			@sortorder = 'desc'
     		else
     			@sortorder = 'asc'
     		end

     		if(params[:orderby] and ['open','resolved','answered','rejected','no_expertise'].include?(params[:orderby]))
     			@orderby = params[:orderby]
     		else 
     			@orderby = 'state'
     		end
        @typelist = transform_typelist(@typelist)
       	# now sort it, if the orderby is 'state', don't bother, it's already sorted from the mysql query
     		if(@orderby != 'state')
     		  column = instance_variable_get("@" + @orderby).find_all { |k,v| k!= "ZZ"}   #turn into sortable array
     			@typelist = ((@sortorder == 'asc') ? column.sort{|a,b| ((a[1]) ? a[1] : 0) <=> ((b[1]) ? b[1] : 0) } : 
     			                         column.sort{|a,b| ((b[1]) ? b[1] : 0) <=> ((a[1]) ? a[1] : 0)})
     		end
     end

     def transform_typelist(typl)
         nar = []; typl.map { |nm| nar << [nm.name] } 
         nar
     end 
       
     def activity_by_tag
          @filteredparams = FilterParams.new(params)  #can this be useful here? for hackers of the url? filter by location as well...
          @filteredoptions = @filteredparams.findoptions
           @typename = params[:category] ;  @locid = nil; @statename=nil ; @locname=nil ; @filtstr=""    #was :Category
           @statename = params[:State]    #in case someone hacks in &State=NY...use abbreviation
           if (loc=Location.find_by_id(params[:location]))  #in case someone hacks in &location=n...
                @locname = "#{loc.id} (" + loc.name + ")"
                @locid = loc.id
                if (@statename && (loc.abbreviation != @statename  || loc.name != @statename))   ##someone typed in both and they don't match
                    params[:State] = nil    ##currently not allowing mutliple locations filtering
                    @statename = nil
                end                           
            end
            if params[:State] && !@locid
             if (loc=Location.find_by_abbreviation(params[:State])) || (loc=Location.find_by_name(params[:State]))
               @locid = loc.id
               @locname = loc.name
             end
            end
           @filteredoptions.merge!({:location => loc}) if (@locid && !params[:location])  ##should probably add :State into the FilterParams wantsparameter lists
            cat = Category.find_by_name(@typename); ((@locid) ? @filtstr = "Filtered by Location= #{@locname}" : "") 
            
             @earliest_date = SubmittedQuestion.find_earliest_record.created_at.to_date
          	 @latest_date = Date.today
          	 @dateinterval = validate_datepicker({:earliest_date => @earliest_date, :default_datefrom => @earliest_date, :latest_date => @latest_date, :default_dateto => @latest_date})
             
            @typelist = [cat]
            if !cat.nil?
                #tagname = Tag.normalize_tag(cat.name)
                @rept = Aaereport.new({:name => "ActivityCategory", :filters => @filteredoptions})
            else
                redirect_to :controller => 'aae/reports', :action => 'sel_active_cats' 
            end
       end  

       def sel_active_cats
        @cats = Category.find(:all, :order => 'name')
       end
       
             
       def siftna(sa)
          #sift the n/a to the bottom
           tmparray = Array.new; zeroarray=Array.new
           k = sa.size; i = 0
           while i < k do
             if sa[i][1]   # let us not forget that zero could be a legitimate percent change 
               tmparray << sa[i]
             else
               zeroarray << sa[i]
             end
             i = i + 1
           end
           tmparray + zeroarray
        end
   
       
        def order_clause(order_by = "submitted_questions.question_updated_at", sort = "desc")
           if !params[:order_by_field].nil?   
             order_by = params[:order_by_field]
             if params[:order_by_field] == "id"
               order_by = "submitted_questions.id"
             elsif params[:order_by_field] == "squpdated"
               order_by = " submitted_questions.updated_at"
         #    elsif params[:order_by_field] == "sqid"
         #      order_by = "submitted_questions.id"
             end
           end

           if params[:sortorder] and params[:sortorder] == 'a'
             sort = "asc"
           end

           order_clause = order_by + " " + sort

         end

        def display_tag_questions
            @cat = Category.find_by_name(params[:category])
            @comments=nil; @edits=params[:descriptor]; @idtype='id'
            aux = nil ; @catname = params[:category]; locid = params[:locid] ; @loc = Location.find_by_id(locid)
             @earliest_date = SubmittedQuestion.find_earliest_record.created_at.to_date
             @latest_date = Date.today
             @dateinterval = validate_datepicker({:earliest_date => @earliest_date, :default_datefrom => @earliest_date, :latest_date => @latest_date, :default_dateto => @latest_date})
             @date1 = @dateinterval[0]; @date2=@dateinterval[1]; @dateFrom = @date1; @dateTo = @date2
           
            @desc = params[:descriptor]; @numb = params[:num].to_i
             if (@edits.length > 8)
               if (@edits[0..7]=="Resolved")
                 aux = @edits[8].chr
                 @edits = "Resolved"
               end
             end
       
              joins = ((locid) ? [:categories, :location] : [:categories])
              (@desc=="New") ? @pgt = " Newly Submitted Questions in '#{@cat.name}'  " : @pgt = " Questions Resolved from Ask an Expert for '#{@cat.name}'"
              (params[:locname]) ? @filtstr = "Filtered by Location = #{params[:locname]} "  : ""
              
               @questions = SubmittedQuestion.find_questions({:cat => @cat, :desc => @edits, :aux => aux, :location => @loc, :numparm => "all",
                  :args => { :joins => joins, :order => order_clause("submitted_questions.updated_at", "desc"),
                       :page => params[:page], :per_page => AppConfig.configtable['items_per_page']}})                                                
              @min = 124
        end
        
        ######   User Report of Ask an Expert Activity #####
        
        def user_report

        end
         
         def locate
            if params[:u].nil?
              flash[:failure] = "No Username entered. Please enter a username and try again."
              redirect_to :controller => 'reports', :action => 'user_report'
              return
            elsif params[:u].strip == ''
              flash[:failure] = "No Username entered. Please enter a username and try again."
              redirect_to :controller => 'reports', :action => 'user_report'
              return
            end

            #if there are any alpha characters, look up in users table

            user = nil

            if params[:u] =~ /^[0-9]+$/
              user = User.find_by_id(params[:u])
           end

            if !user.nil?
              redirect_to :action => 'user', :id => user.id
            else
              user = User.find_by_login(params[:u])
              if !user.nil?
                redirect_to :action => 'user', :id=>user.id
              else
                flash[:failure] = "We can't find any record for <strong>#{params[:u]}</strong>. Please check the username spelling and try again."
                redirect_to :controller => 'reports', :action => 'user_report'
              end   
            end
          end
          
        
        def user
          @earliest_date = SubmittedQuestion.find_earliest_record.created_at.to_date
          @latest_date = Date.today
          @dateinterval = validate_datepicker({:earliest_date => @earliest_date, :default_datefrom => @earliest_date, :latest_date => @latest_date, :default_dateto => @latest_date})
          @date1=@dateinterval[0]; @date2 = @dateinterval[1]
 
      
           if params[:id] =~ /^[0-9]+$/
              @user = User.find_by_id(params[:id])
           else
              @user = User.find_by_login(params[:id])   # in case anyone hacks in the user login, not the number id
           end
         
          if @user
             @uresolved = @user.resolved_questions.date_subs(@date1, @date2).count(:conditions => "status_state in (#{SubmittedQuestion::STATUS_RESOLVED}, #{SubmittedQuestion::STATUS_REJECTED}, #{SubmittedQuestion::STATUS_NO_ANSWER})")
             @uassigned = @user.ever_assigned_questions(:dateinterval => @dateinterval).count
             @ucurrently_assigned = @user.assigned_questions.count(:conditions => "status_state= #{SubmittedQuestion::STATUS_SUBMITTED} and spam= false")
             @avgstdresults = @user.get_avg_resp_time(:dateinterval => @dateinterval)
           end
       #   @myid = @currentuser
          if @user.nil? #|| @myid.nil? 
            redirect_to :controller => 'reports', :action => 'user_report'
          end
          @repaction = "user"
        end
        
        def display_questions
           @user = User.find_by_id(params[:user]);
           @comments=nil; @edits=nil; 
           @date1 = params[:datefrom]; @date2 = params[:dateto]
           @desc = params[:descriptor]; @numb = params[:num].to_i; joins = nil; group_name = nil
           descl = @desc

           select_string = " submitted_questions.* "
           if @desc=="Assigned as an Expert" || @desc=="Currently Assigned as an Expert"
             select_string = select_string + " , recipient_id "
             joins = [:submitted_question_events]
             group_name = "submitted_question_id"
             descl = "was " + @desc
           end
            
             @pgt = "Questions #{@user.first_name} #{@user.last_name} #{descl} "
             @faq = nil; @idtype='id'
        
              @questions = SubmittedQuestion.find_questions({:numparm => "all", :cat => @user, :desc => @desc, :dateinterval => [@date1,@date2],
                                                   :args => {:select => select_string,
                                                            :joins => joins,
                                                            :order => order_clause("submitted_questions.updated_at", "desc"),
                                                            :group => group_name,
                                                            :page => params[:page],
                                                            :per_page => AppConfig.configtable['items_per_page']}})
    
        end
        
        ####   end of User Report for Ask an Expert Activity #####
         

        ## Expertise Report
        def answerers
         @cats = Category.find(:all, :conditions => "parent_id is null", :order => 'name')
         @csize = @cats.size
         @catcnt = Category.count_users_for_rootcats
         @locs = ExpertiseLocation.find(:all, :order => 'entrytype, name')
         @lsize = @locs.size 
         @locsum = ExpertiseLocation.count(:joins => [:users], :group => "expertise_location_id", :order => "entrytype, name")
        end

        def state_answerers
         @filteredparams = FilterParams.new(params) 
         @filteredoptions = @filteredparams.findoptions 
          if params[:id]
            catobj = Category.find_by_id(params[:id])
            if catobj
              @catname = catobj.name
              catid = params[:id]
            end
          else
            if params[:category]
              catobj = Category.find_by_name(params[:category])
              if catobj
                @catname = catobj.name
                catid = catobj.id
              end
            end
          end 
          if (@catname  && @catname != "")
            @locs = ExpertiseLocation.find(:all, :order => 'entrytype, name')
            @loccnt = ExpertiseLocation.expert_loc_userfilter_count(@filteredoptions)
            @user_list = catobj.users.find(:all, :order => "users.last_name")
            setup_routers_and_wranglers
            
            @capcatname = @catname[0].chr.to_s.upcase + @catname[1..(@catname.length - 1)]
            @lsize = @locs.size
            @usize = @user_list.size
          else
            redirect_to :action => 'answerers'
          end
        end

        def category_county
            #An example using People's general techniques as much as possible
           @filteredparams=FilterParams.new(params)
           @filteredoptions = @filteredparams.findoptions
             @cats = Category.find(:all, :conditions => "parent_id is null", :order => "name")
             @csize = @cats.size 
             @cnties = ExpertiseCounty.find(:all,  :conditions => "expertise_location_id = #{params[:location]}", :order => 'countycode, name').collect { |nm| [nm.name, nm.id]}       
             @ysize = @cnties.size
             @catcnt = Category.catuserfilter_count(@filteredoptions)
             @cntycnt = ExpertiseCounty.expert_county_userfilter_count(@filteredoptions)
             
             @user_list = ExpertiseLocation.find_by_id(params[:location]).users.find(:all, :order => "users.last_name")
             setup_routers_and_wranglers
             
             @usize = @user_list.size ; @locid = params[:location]
             @statename = ExpertiseLocation.find_by_id(params[:location]).name
             
        end

        def category_users
           @filteredparams=FilterParams.new(params)
           @filteredoptions = @filteredparams.findoptions
           getparams = ParamsFilter.new([:county, :location], params)
           @statename = nil; @county = nil; @countyid = nil; @locid = nil
          
     #     if params[:State]
    #          @statename = params[:State]
    #         @locid = ExpertiseLocation.find_by_name(@statename).id
    #      end
    #      if params[:County]
    #        @county = params[:County]
    #        @countyid= params[:county]
    #      end
    #      if (@statename && @county && @statename != "" && @county != "")
           if getparams.location && getparams.county
             @countyid = getparams.county.id ; @county = getparams.county.name
             @statename = getparams.location.name
             @locid = ExpertiseLocation.find_by_name(@statename).id
             @cats = Category.find(:all, :conditions => "parent_id is null ", :order => 'name')
             @csize = @cats.size
             @ctycnt = Category.catuserfilter_count(@filteredoptions)
             
             @user_list = ExpertiseCounty.find_by_id(@countyid).users.find(:all, :order => "users.last_name")
             setup_routers_and_wranglers
             
             @usize = @user_list.size
          end
        end

        def category_county_users
          # todo -- need validation of county id, state id, and category - ATH...
          # fixed bug where ExpertiseCounty.find_by_id(countyid) used to be find_by_name...problem is, "All" as a name is in all locations
          #    plus, some other county names are found in multiple states...ie, "Madison" --SMD
          # use some new filter params methods for sake of overall consistency, and use noncapitalized versions for consistency --SMD
          getparams = ParamsFilter.new([:county, :location, :category], params)
          (getparams.location) ? @statename = getparams.location.name : @statename=nil
          (getparams.location) ? @locid = getparams.location.id : @locid=nil
          (getparams.county) ? @county = getparams.county.name : @county = nil
          @catname = getparams.category[0]
          !(getparams.category.blank?) ? category=Category.find_by_name(@catname) : category=nil
           
          
    #      if params[:State]
    #        @statename = params[:State]
    #        @locid = ExpertiseLocation.find_by_name(@statename)
    #      end                                         ## Note, old way commented out here takes in production mode ~337 ms
    #      if params[:County]                         ## new way, ~339 ms on local machine
    #        @county = params[:County]
    #    end
    #      if params[:Category]
    #        @catname = params[:Category]
    #        category = Category.find_by_name(params[:Category])
    #      end
    #      if (@statename && @county && @catname && @statename !="" && @county != "" && @catname != "")
           if getparams.location  && !getparams.category.blank? && getparams.county  
            @capcatname = @catname[0].chr.to_s.upcase + @catname[1..(@catname.length - 1)]
            
            expertise_county= ExpertiseCounty.find(:first, :conditions => ["expertise_location_id=#{ExpertiseLocation.find_by_name(@statename).id} and name=?", @county])
        
            @user_list = User.experts_by_county(expertise_county).experts_by_category(category.id) 
             
            setup_routers_and_wranglers
          
            @usize = @user_list.size
           end
        end

        def county_answerers
          # todo -- need validation of county id, state id, and category - ATH
          getparams = ParamsFilter.new([ :location, :category], params)
          (getparams.location) ? @statename = getparams.location.name : @statename=nil
          (getparams.location) ? @locid = getparams.location.id : @locid=nil
    #      if params[:id]
    #         @statename = ExpertiseLocation.find_by_id(params[:id]).name
    #         @locid = params[:id]
    #      else
    #        if params[:State]
    #          @statename = params[:State]
    #          @locid = ExpertiseLocation.find_by_name(@statename).id
    #        end
    #      end
    #      @catname = params[:Category]
     #     if (!@catname || @catname == "")
          if getparams.category.blank?
              redirect_to :action => 'answerers'
          end
          @catname = getparams.category[0]
          category = Category.find_by_name(@catname)     #was params[:Category]
                
          if params[:dir]
            @dir = params[:dir]
          end
         # if (@statename && @statename != "")
       
          if getparams.location
            @cnties = ExpertiseCounty.find(:all,  :conditions => "expertise_location_id = #{ExpertiseLocation.find_by_name(@statename).id}", :order => 'countycode, name').collect { |nm| [nm.name, nm.id]}
            @cntycnt = ExpertiseCounty.count_answerers_for_county_and_category(@catname, @statename)
            @capcatname = @catname[0].chr.to_s.upcase + @catname[1..(@catname.length - 1)]
            
            @user_list = User.experts_by_location(ExpertiseLocation.find_by_id(@locid)).experts_by_category(category.id)
            setup_routers_and_wranglers
            
            @csize = @cnties.size
            @usize = @user_list.size
          else
            redirect_to :action => 'state_answerers', :category => @catname
          end  
        end

        def answerers_lists
          # todo -- need validation of county id, state id, and category - ATH
          
            getparams = ParamsFilter.new([:county, :location, :category], params)
            (getparams.location) ? @statename = getparams.location.name : @statename=nil
            (getparams.location) ? @locid = getparams.location.id : @locid=nil
            (getparams.county) ? @county = getparams.county.name : @county = nil
            @catname = getparams.category[0]
            !(getparams.category.blank?) ? category=Category.find_by_name(@catname) : category=nil
            
          if params[:dir]
            @dir=params[:dir]
          end
          if (!category)
            redirect_to :action => 'answerers'
          end
          
          if !getparams.location 
            redirect_to :action => 'state_answerers', :category => @catname
          end
          @locid = ExpertiseLocation.find_by_name(@statename).id
          if (@county)
            expertise_county = ExpertiseCounty.find(:first, :conditions => ["expertise_location_id=#{@locid} and name=?", @county])
           
            @capcatname = @catname[0].chr.to_s.upcase + @catname[1..(@catname.length - 1)]
          # form array of users for selected county
        
            @user_list = User.experts_by_county(expertise_county).experts_by_category(category.id)
            setup_routers_and_wranglers
            
            @usize = @user_list.size
          else
            redirect_to :action => 'county_answerers', :location => @locid, :category => @catname
          end
        end
        
    ##  End of Expertise Report
    
    
    ####   State Report for Ask an Expert  #####
    
 #   def state_report

 #    end
    
    
  
     def state
        @earliest_date = SubmittedQuestion.find_earliest_record.created_at.to_date
      	@latest_date = Date.today
      	@dateinterval = validate_datepicker({:earliest_date => @earliest_date, :default_datefrom => @earliest_date, :latest_date => @latest_date, :default_dateto => @latest_date}) 
      	@date1 = @dateinterval[0]; @date2 = @dateinterval[1]  
        
        @typeobj = Location.find_by_id(params[:location])
       if (@typeobj) 
         @typename = @typeobj.name
         @type = "State" ; @typel="state" ; 
         @locid = @typeobj.id; @county_id = nil
      
           @reguser = User.date_users(@date1, @date2).count(:conditions => "location_id=#{@locid}")
            @open = SubmittedQuestion.date_subs(@date1, @date2).count(:conditions =>  " status_state=#{SubmittedQuestion::STATUS_SUBMITTED} and location_id=#{@locid} and spam=FALSE")
           ##################################################################################################################################################        
           # The following is the breakdown of Ask an Expert questions where two different perspectives are requested for the state and shown on the report.
           # The first perspective is on the questions that were asked that pertain to the state. For these we want to know the total resolved,
           # and how they were resolved, as in answered, rejected, or given the no-answer of "we do not have this expertise".
           ##################################################################################################################################################
        #   (@answp, @answpa, @answpr, @answpn)= SubmittedQuestion.get_answered_question_by_state_persp({:bywhat => "pertaining",:location => @typeobj, :dateinterval => @dateinterval})
           (@resolved_pertaining_to_area, @answered_pertaining_to_area, @rejected_pertaining_to_area, @no_answered_pertaining_to_area)= SubmittedQuestion.get_answered_question_by_state_persp({:bywhat => "pertaining",:location => @typeobj, :dateinterval => @dateinterval})
           
           ###############################################################################################################################################################################
           # The second perspective for Ask an Expert questions for the state is about what answerers for the state have done.
           # Similarly, there is a breakdown for this on total resolved, and then number resolved by answering, rejecting, or giving the 'no-answer' of "we do not have this expertise."
           ###############################################################################################################################################################################   
        #  (@answm, @answma, @answmr, @answmn)= SubmittedQuestion.get_answered_question_by_state_persp({:bywhat => "member", :location => @typeobj, :dateinterval => @dateinterval})   
           (@resolved_by_member, @answered_by_member, @rejected_by_member, @no_answered_by_member)= SubmittedQuestion.get_answered_question_by_state_persp({:bywhat => "member", :location => @typeobj, :dateinterval => @dateinterval})

      
       else
         redirect_to :controller => 'aae/reports', :action => 'index'
       end
     end
     
     def display_state_questions
         @type = params[:type]
         @loc = Location.find_by_id(params[:location]);
         @locid = @loc.id
         if (@type == 'State')    
             @county = nil; @typename = @loc.name; @statename = @loc.name; @county_id=nil
         else
             @countyobj = County.find_by_id(params[:county]);
             if @countyobj
               @county=@countyobj.name 
               @typename = @county ; @statename = @loc.name 
               @county_id = @countyobj.id
             end
         end
         @desc = params[:descriptor];  
          @comments=nil;  @edits=params[:descriptor]; @numb = params[:num].to_i
         if (@edits.length > 9)
           if (@edits[0..7]=="Resolved")
             @edits = @edits[0..8]
           end
         end
 
           @date1 = params[:datefrom] ; @date2 = params[:dateto]
           @limit_string = "Only up to 100 are shown."
           jstring = nil
            case @edits
            when "Submitted"
                @pgt = "Submitted Questions pertaining to #{@typename}"
            else
               jstring = [:resolved_by] 
               (@edits[8].chr=="P") ? @pgt = "Resolved Questions pertaining to #{@typename}" : @pgt="Questions Resolved by a member in #{@typename}" 
            end
             @faq = nil; @idtype = 'id'  
     
              @questions = SubmittedQuestion.find_state_questions({:location => @loc, :county => @county_id, :desc => params[:descriptor], :dateinterval => [@date1,@date2], :numparm => "all",
                :args => {:joins => jstring,
                        :order => (@edits=="Submitted" || @edits[0..7]=="Resolved") ? order_clause("submitted_questions.updated_at", "desc") : order_clause,
                        :page => params[:page],
                        :per_page => AppConfig.configtable['items_per_page']}})
              
          @pgtl = @pgt
          if (@type=='County')
            @pgtl = @pgt + " county/parish in #{@loc.name}"
          end
          @min = 124
      end

      def display_state_users
         @type = params[:type]
         @loc = Location.find_by_id(params[:location])
         if (@type == 'State')  
            @county = nil; @typename = @loc.name; @county_id=nil
         else
           @countyobj = County.find_by_id(params[:county]); 
           if @countyobj
             @county = @countyobj.name; @typename = @county; @county_id=@countyobj.id
           end
         end
         @desc = params[:descriptor]; 
          @comments=nil; @edits=params[:descriptor]; @numb = params[:num].to_i   #look at find_state-users, use :county not :countyname?
         @date1 = params[:datefrom]; @date2 = params[:dateto]
    
         @users = User.find_state_users({:location => @loc, :county => @county_id, :dateinterval => [@date1, @date2], :numparm => "all", :args => {
             :order => "last_name", :page => params[:page], :per_page => AppConfig.configtable['items_per_page'] }})
      end
     
     
      ####  County Report for Ask an Expert ####

     def county_select
       @date1=nil; @date2=nil; @dateFrom=nil; @dateTo=nil
       @date1 = params[:datefrom]; @date2 = params[:dateto]
       if params[:location]  
           @loc = Location.find_by_id(params[:location])
       end
       if (@loc && @loc.name != "")
         @locid=@loc.id; @statename = @loc.name
         @counties= County.find(:all,  :conditions => "location_id = #{@loc.id} and name<>'All'", :order => 'countycode, name')
       else
         redirect_to :controller => 'aae/reports', :action => 'index'
       end
     end


     def county
        @earliest_date = SubmittedQuestion.find_earliest_record.created_at.to_date   #find county and state names by ids
       	@latest_date = Date.today
       	@dateinterval = validate_datepicker({:earliest_date => @earliest_date, :default_datefrom => @earliest_date, :latest_date => @latest_date, :default_dateto => @latest_date}) 
       	@date1 = @dateinterval[0]; @date2 = @dateinterval[1]
       @typeobj = County.find_by_id(params[:county]) ; ((@typeobj) ? @typename = @typeobj.name : @typename= nil)   #change all these state and county names to ids where feasible
       @county = @typename
       if @typeobj
          @county_id= @typeobj.id
          @loc=Location.find_by_id(@typeobj.location_id)
          if @loc
            @statename = @loc.name; @locid = @loc.id
          end
         @type="County"; @typel="county" ;   
        
       
           @reguser = User.date_users(@date1, @date2).count(:conditions => "county_id = #{@typeobj.id}")
         
        @open = SubmittedQuestion.date_subs(@date1, @date2).count(:conditions =>  " status_state=#{SubmittedQuestion::STATUS_SUBMITTED} and county_id=#{@typeobj.id} and spam=FALSE")
         ##############################################################################################################################################################
         # The following is the breakdown of Ask an Expert questions where two different perspectives are requested for the county and shown on the report.
         # The first perspective is on the questions that were asked that pertain to the county. For these we want to know the total resolved,
         # and how they were resolved, as in answered, rejected, or given the no-answer of "we do not have this expertise".
         ##############################################################################################################################################################
         
        # (@answp, @answpa, @answpr, @answpn)= SubmittedQuestion.get_answered_question_by_county_persp({:bywhat => "pertaining", :county => @typeobj, :dateinterval => @dateinterval})
         (@resolved_pertaining_to_area, @answered_pertaining_to_area, @rejected_pertaining_to_area, @no_answered_pertaining_to_area)= SubmittedQuestion.get_answered_question_by_county_persp({:bywhat => "pertaining", :county => @typeobj, :dateinterval => @dateinterval})
         
          ##############################################################################################################################################################################      
          # The second perspective for Ask an Expert questions for the county is about what answerers for the county have done.
          # Similarly, there is a breakdown for this on total resolved, and then number resolved by answering, rejecting, or giving the 'no-answer' of "we do not have this expertise."
          ##############################################################################################################################################################################
           #  (@answm, @answma, @answmr, @answmn)= SubmittedQuestion.get_answered_question_by_county_persp({:bywhat => "member", :county => @typeobj, :dateinterval => @dateinterval}) 
          (@resolved_by_member, @answered_by_member, @rejected_by_member, @no_answered_by_member)= SubmittedQuestion.get_answered_question_by_county_persp({:bywhat => "member", :county => @typeobj, :dateinterval => @dateinterval})   
         
     else
       redirect_to :controller => 'aae/reports', :action => 'index'
     end
     
    end  
    
    ##### end of County Report for Ask an Expert ####
    
    ##  Response Times Report
    
    def response_checkbox_setup(parmdate, public_source, widget_source, via_conduit)
        #initially make sure checkboxes retain what was last in them
       if !session[via_conduit]
         pub = true; widget = true
       else
         pub = session[via_conduit][0]; widget = session[via_conduit][1]
       end
        #change the qualifiers acording to the checkbox change
        if params[parmdate]
          if params[public_source]
             pub = params[public_source] 
          else
             pub = false
          end
          if params[widget_source] 
             widget = params[widget_source]
          else
             widget = false
          end 
          if session[via_conduit]
             session[via_conduit]= [pub, widget]
           end
        end
        return [pub, widget]  
     end


     def response_dates_upper(repaction)
           (public1, widget1)= response_checkbox_setup(:upper, :public_sourcea, :widget_sourcea, :via_conduita)
           #Retain other part of page and modify this section as appropriate; this statement below is to keep dates for upper if upper was not changed this time
           @date1 = params[:dat1]; @date2 = params[:dat2];  
            if params[:upper]
               @first_set="y"
               if params[:commit]=="Clear" ||  params[:commit]=="Last 90 days"
                 @clear1 = "y"
               end
            end
            if !@date1 && @clear1=="n"     #we are changing the upper this time
               
                 params[:datefrom]=params[:from][0] if params[:from] ; params[:dateto]=params[:to][0] if params[:to]
                    @earliest_date = SubmittedQuestion.find_earliest_record.created_at.to_date
                   	@latest_date = Date.today
                   	@dateinterval = validate_datepicker({:earliest_date => @earliest_date, :default_datefrom => @prior90th, :latest_date => @latest_date, :default_dateto => @latest_date})
                    @date1 = @dateinterval[0]  ; @date2 = @dateinterval[1]   
              
              if (@date1 && @date2)
                @unselected=nil
                @nodays = @date2 - @date1
                if @nodays > 30 ; @nodays=30; end
              end
            else    # This path is generally taken when we have not changed the upper date
              if @clear1 != "y"  
         #       @date1 = params[:datefrom] if params[:upper]; @date2 = params[:dateto] if params[:upper]
                @date1 = @date1.to_date; @date2 = @date2.to_date
                @dateinterval=[@date1, @date2]
                if (@date1 && @date2)
                  @unselected=nil
                  @nodays = @date2 - @date1
                  if @nodays > 30 ; @nodays=30; end
                end
              else
                @date1 = nil; @unselected="y"
              end
            end
           [@date1, @date2, public1, widget1, @nodays]
     end      

     def response_avgs_upper(public1, widget1)
            extstr = SubmittedQuestion.get_extapp_qual(public1,widget1)
            @number_questions = SubmittedQuestion.find_once_externally_submitted({:dateinterval => [@date1,@date2], :external => extstr})
            @avg_response_time = SubmittedQuestion.get_avg_response_time({:dateinterval => [@date1,@date2], :external => extstr})
            @avg_resp_past30 = SubmittedQuestion.get_avg_response_time_past30({:dateinterval => [@date1,@date2], :external => extstr, :nodays => @nodays})
       #     @avg_still_open = SubmittedQuestion.find_externally_submitted(@date1, @date2, public1, widget1)
            @avg_still_open = SubmittedQuestion.find_externally_submitted({:dateinterval => [@date1,@date2], :external => extstr})
            if (params[:upper])
                 session[:first_set]= "y"
            end
     end

     def response_dates_lower(repaction)
        #make sure we read what was last in the checkboxes and retain it
        (public2, widget2) = response_checkbox_setup(:lower, :public_sourceb, :widget_sourceb, :via_conduitb)
         if params[:lower]
          @sec_set="y"
          if params[:commit]=="Clear" || params[:commit]=="remove"
            @clear2 = "y"
          end
         end
        #retain fields; this statement below is to keep the dates from lower if lower was not changed this time (upper was)
         @datec1 = params[:compare_dat1]; @datec2=params[:compare_dat2]
         # if there is not a date being retained, and the user did not choose to clear or remove
          if ((!@datec1) && @clear2=="n")  
               # This path is taken when we change the lower dates  (the upper set is always present)
               # if dates are being passed in (as from the general to the by_location or by_category), or the user is sending anew from the lower set of compare dates, prepare to absorb or read the dates
               if ((params[:from] && params[:from][1] != "")  or params[:lower] or @sec_set)
                    params[:datefrom]=params[:from][1] if (params[:from] && params[:from][1] !=""); params[:dateto]=params[:to][1] if (params[:to] && params[:to][1] != "")
                    @earliest_date = SubmittedQuestion.find_earliest_record.created_at.to_date
                  	@latest_date = Date.today
                  	@dateintervalc = validate_datepicker({:earliest_date => @earliest_date, :default_datefrom => @prior90th, :latest_date => @latest_date, :default_dateto => @latest_date})
                    @datec1 = @dateintervalc[0]  ; @datec2 = @dateintervalc[1]
               end
            if (@datec1 && @datec2)
              @unselectedc=nil
              @nocdays = @datec2 - @datec1
              if @nocdays >= 30 ; @nocdays=30; end
            end
          else    # This path is generally taken when we have not changed the lower date, value comes from params[:compare_dat1/2]
             if @clear2 != "y"            
            #    @datec1 = params[:datefrom] if params[:lower]; @datec2 = params[:dateto] if params[:lower]
                @datec1 = @datec1.to_date; @datec2 = @datec2.to_date
                @dateintervalc = [@datec1, @datec2]
                if (@datec1 && @datec2)
                   @unselectedc=nil
                    @nocdays = @datec2  - @datec1
                   if @nocdays >= 30 ; @nocdays=30; end
                end
             else
               @datec1 = nil; @unselectedc="y"
             end
           end
          [@datec1, @datec2, public2, widget2, @nocdays]
     end

     def response_avgs_lower(public2, widget2)
         extstr = SubmittedQuestion.get_extapp_qual(public2,widget2)
         @numbc_questions = SubmittedQuestion.find_once_externally_submitted({:dateinterval => [@datec1,@datec2], :external => extstr})
         @avgc_response_time = SubmittedQuestion.get_avg_response_time({:dateinterval => [@datec1,@datec2], :external => extstr})
         @avgc_resp_past30 = SubmittedQuestion.get_avg_response_time_past30({:dateinterval => [@datec1,@datec2], :external => extstr, :nodays => @nocdays})
         @avgc_still_open = SubmittedQuestion.find_externally_submitted({:dateinterval => [@datec1,@datec2], :external => extstr})
          if (params[:lower])
               session[:sec_set]= "y"
          end
     end


     def response_times
       @sec_set = nil; @first_set= nil; @clear1="n"; @clear2="n"
       @first_set = session[:first_set] if session[:first_set]
       @sec_set = session[:sec_set] if session[:sec_set]
       @oldest_date = SubmittedQuestion.find_earliest_record.created_at.to_date
       @prior90th=@oldest_date ; 	@latest_date = Date.today
       @repaction = 'response_times'
       @nodays = 30; @nocdays = 30
       @number_questions_all = SubmittedQuestion.find_externally_submitted({:dateinterval => [@oldest_date, @latest_date], :external => " IS NOT NULL " })
       @avg_response_time_all = SubmittedQuestion.get_avg_response_time({:dateinterval => [@oldest_date,@latest_date], :external => " IS NOT NULL "})
       @avg_resp_past30_all = SubmittedQuestion.get_avg_response_time_past30({:dateinterval => [@oldest_date,@latest_date], :external => " IS NOT NULL ", :nodays => @nodays})
       @avg_open_time_all = SubmittedQuestion.get_avg_open_time({:dateinterval => [@oldest_date,@latest_date], :external => " IS NOT NULL "})
       if params[:upper] || params[:lower]  || @first_set || @sec_set
         (@date1, @date2, public1, widget1, @nodays)=response_dates_upper(@repaction)
         response_avgs_upper(public1, widget1)
         (@datec1, @datec2, public2, widget2, @nocdays) = response_dates_lower(@repaction)
         response_avgs_lower(public2, widget2)
       end
     end  
    
    
    def get_responses_by_category(date1, date2, pub, wgt)
       extstr = SubmittedQuestion.get_extapp_qual(pub, wgt) 
       if extstr == " IS NULL";  return [ {}, {}, {}]; end
       (date1 && date2) ? dateinterval = [date1, date2] : dateinterval = nil
       noq = SubmittedQuestion.get_number_questions({:dateinterval => dateinterval, :external => extstr, :joinclause => [:categories], :groupclause => "category_id"})
       avgr = SubmittedQuestion.get_loc_or_category_average({:dateinterval => dateinterval, :external => extstr, :joinclause => [:categories], :groupclause => "category_id"})
       noopen = SubmittedQuestion.get_number_open({:dateinterval => dateinterval, :external => extstr, :joinclause => [:categories], :groupclause => "category_id"})
       [noq, avgr, noopen]
    end


     def category_response_times
       @typelist = []; @nof= {}; @var1={}; @var2={}; @var3={}
       @nos1={}; @nostopn1={}; @p301 = {}; @ppd1 = {}; @avgchg = {} ; @nos2={}; @nostopn2={}; @p302 = {}; @ppd2 = {}
       @first_set = nil; @sec_set= nil; @clear1="n"; @clear2="n"
       @first_set = session[:left_set] if session[:left_set]
       @sec_set = session[:right_set] if session[:right_set]
       t= Time.now - 90*24*60*60
       @prior90th = t.to_date
       @repaction = 'response_times_by_category'; @pagetype=" Category"; rslts = {}
        #set up defaults   
        (rslts[:no_questions],rslts[:avg_responses], rslts[:avg_waiting]) = get_responses_by_category(nil, nil, true, true)
           # deal with date data
         (@date1, @date2, public1, widget1, @nodays)=response_dates_upper(@repaction)
           # selected dates upper
           (rslts[:nos1_questions], rslts[:avg1_responses],rslts[:avg1_still_open])= get_responses_by_category(@date1, @date2, public1, widget1)
              if (params[:upper])
               session[:left_set]= "y"
             end
         (@datec1, @datec2, public2, widget2, @nocdays) = response_dates_lower(@repaction)
            # selected dates lower
          if (@datec1 && @datec2)
            (rslts[:nos2_questions], rslts[:avg2_responses], rslts[:avg2_still_open])= get_responses_by_category(@datec1, @datec2,  public2, widget2)
             if (params[:lower])
              session[:right_set]= "y"
          end
        end
       @type = "Category"
        @typelist= Category.find(:all, :conditions => "parent_id is null", :order => 'name')
        response_times_summary(rslts)
     end
     
     
     def sort_response_times
       	if(params[:sortorder] and params[:sortorder]=='d')
      			@sortorder = 'desc'
      		else
      			@sortorder = 'asc'
      		end

      		if(params[:orderby] and [ 'nos1', 'nostopn1', 'ppd1', 'avgchg','nos2','nostopn2','ppd2'].include?(params[:orderby]))
      			@orderby = params[:orderby]
      		else 
      			@orderby = 'State'
      		end
      	  russ = []
         russ = transform_typelist(@typelist)
         # now sort it...
         
       	if(@orderby != 'State')
       		  column = instance_variable_get("@" + @orderby).find_all { |k,v| k!= "ZZ"}   #turn into sortable array
        			russ= ((@sortorder == 'asc') ? column.sort{|a,b| ((a[1]) ? a[1] : 0) <=> ((b[1]) ? b[1] : 0) } : 
        			                         column.sort{|a,b| ((b[1]) ? b[1] : 0) <=> ((a[1]) ? a[1] : 0)})
       end
       if @orderby=='avgchg' || @orderby[0..2]=='ppd'
          russ = siftna(russ)
       end
       @typelist = russ
    end

     def response_times_by_category
        if !params[:from]
          @unselected = "y" ; @unselectedc="y" 
        end
        if params[:from] && params[:from][1]==""
               @sec_set = nil;  session[:right_set] = nil
        end
        category_response_times
        sort_response_times
     end

     def get_responses_by_location(date1, date2, pub, wgt)
       extstr = SubmittedQuestion.get_extapp_qual(pub, wgt) ; avgrh = {}
        if extstr == " IS NULL";  return [ {}, {}, {}]; end
        (date1 && date2) ? dateinterval = [date1, date2] : dateinterval = nil
        noq = SubmittedQuestion.resolved_or_assigned_count({:dateinterval => dateinterval, :external => extstr})
        avgr = SubmittedQuestion.get_loc_or_category_average({:dateinterval => dateinterval, :external => extstr, :joinclause => [:assignee], :groupclause => "users.location_id"})
        noopen = SubmittedQuestion.get_number_open({:dateinterval => dateinterval, :external => extstr, :joinclause => [:assignee], :groupclause => "users.location_id"})
        [noq, avgr, noopen]
      end

      def response_times_summary(results_hash)
        stuv = nil
        @typelist.each do |st|
           (@type=='Location') ? stuv = st.id : stuv = st.id.to_s
           @nof[st.name]= results_hash[:no_questions][stuv] ; @nos1[st.name]=@nof[st.name]
           @var1[st.name]= results_hash[:avg_responses][stuv]; @ppd1[st.name]= @var1[st.name]
           @var3[st.name]= results_hash[:avg_waiting][stuv]; @nostopn1[st.name]= @var3[st.name]
           if (@date1 && @date2)
              @nos1[st.name]= results_hash[:nos1_questions][stuv]
              @ppd1[st.name]= results_hash[:avg1_responses][stuv]
              @nostopn1[st.name]= results_hash[:avg1_still_open][stuv]
           end
           if (@datec1 && @datec2)
              @nos2[st.name] = results_hash[:nos2_questions][stuv]
              @ppd2[st.name] = results_hash[:avg2_responses][stuv]
              @nostopn2[st.name] = results_hash[:avg2_still_open][stuv]
           end
            if (@ppd1[st.name] && @ppd2[st.name] && @ppd1[st.name] > 0 )
              @avgchg[st.name]= (@ppd2[st.name]- @ppd1[st.name]).to_f/@ppd1[st.name] * 100
            else
              @avgchg[st.name]= nil
            end
        end

      end

      def location_response_times      
         @typelist = []; @nof= {}; @var1={}; @var2={}; @var3={}
         @nos1={}; @nostopn1={}; @p301 = {}; @ppd1 = {}; @avgchg={};  @nos2={}; @nostopn2={}; @p302 = {}; @ppd2 = {}
         @first_set = nil; @sec_set= nil; @clear1="n"; @clear2="n"
         @first_set = session[:set1] if session[:set1]
         @sec_set = session[:set2] if session[:set2]
         t= Time.now - 90*24*60*60
         @prior90th = t.to_date; 
         @repaction = 'response_times_by_location' ; rslts={}
          (rslts[:no_questions],rslts[:avg_responses],rslts[:avg_waiting]) = get_responses_by_location(nil, nil,  true, true)
             # deal with date data
           (@date1, @date2, public1, widget1, @nodays)=response_dates_upper(@repaction)
             # selected dates upper
             (rslts[:nos1_questions], rslts[:avg1_responses], rslts[:avg1_still_open])= get_responses_by_location(@date1, @date2,  public1, widget1)
              if params[:upper]
                 session[:set1]= "y"
               end
           (@datec1, @datec2, public2, widget2, @nocdays) = response_dates_lower(@repaction)
              # selected dates lower
            if (@datec1 && @datec2)
              (rslts[:nos2_questions], rslts[:avg2_responses], rslts[:avg2_still_open])= get_responses_by_location(@datec1, @datec2,  public2, widget2)
              if params[:lower]
                session[:set2]= "y"
              end
            end
         @type = "Location"; @pagetype="Responder Location"
          @typelist= Location.find(:all,  :order => 'entrytype, name') 
          response_times_summary(rslts)
          
       end

       def response_times_by_location
          if !params[:from]
            @unselected = "y" ; @unselectedc="y" 
          end
          if params[:from] && params[:from][1]==""
             @sec_set = nil;  session[:set2] = nil
          end
          location_response_times
          sort_response_times
       end
       
       ## end of Response Times Report   
  
    #### Start of Responders by Category Report ####
       def resolved_responders_by_category
         @responders_by_category= Hash.new
         @total_resolved_by_category = Hash.new
         @categorylist = Category.find(:all, :conditions => "parent_id is null", :order => 'name')
          @categorylist.each do |category|
            userlist = User.submitted_question_resolvers_by_category(category)
            if(!userlist.blank?)
              @responders_by_category[category.name] = userlist
              # resolved_count is a query-generated field from a custom select in submitted_question_resolvers_by_category
              @total_resolved_by_category[category.name] = userlist.map{|u| u.resolved_count.to_i}.sum
            else
              @total_resolved_by_category[category.name] = 0
            end       
          end
           
       end

       def display_discrete_responder_questions
          @cat = Category.find_by_name(params[:category]); @resolver=User.find_by_id(params[:id]) if params[:id]
          @resolver=User.find_by_id(params[:user]) if (params[:user] && !params[:id])   
          @comments=nil; @edits="Resolved"; @idtype='id'; @user = @resolver ; @catname = @cat.name
          @desc = "Resolver" ; aux =@resolver.id.to_s
          @numb = params[:num].to_i
      
            joins = [:categories]
           
            @pgt = " Questions Resolved by #{@resolver.first_name} #{@resolver.last_name} for '#{@catname}'"
            @faq = nil; @idtype='id'

             @questions = SubmittedQuestion.find_questions({:cat => @cat, :desc => @desc, :aux => aux, :numparm => "all", 
               :args => {:joins => joins, :order => order_clause("submitted_questions.updated_at", "desc"),
                     :page => params[:page], :per_page => AppConfig.configtable['items_per_page']}})                                                          

      
            @min = 124
      
       end
   ####   End of Responders by Category Report ###
      

	def assignee
		# validate dates
		@earliest_date = SubmittedQuestion.find_earliest_record.created_at.to_date
		@latest_date = Date.today
		@dateinterval = validate_datepicker({:earliest_date => @earliest_date, :default_datefrom => @earliest_date, :latest_date => @latest_date, :default_dateto => @latest_date})           
    
		# aae filter routines
		# TODO: simplify!!
		list_view
		set_filters    #pick up filters set in aae
		filter_string_helper
		@filteroptions = {:category => @category, :location => @location, :county => @county, :source => @source}
   
		#get list of assignee users  (expertise users)
		# Roles (id,name)
		# 1,Administrator
		# 2,Community Administrator
		# 3,Uncategorized Question Wrangler
		# 4,Auto Route Questions
		# 5,Receive Escalations
		# 6,Auto Route Widget Questions

		# sortorder
		if(params[:sortorder] and ['d','descending','desc'].include?(params[:sortorder].downcase))
			@sortorder = 'desc'
		else
			@sortorder = 'asc'
		end
		
		if(params[:orderby] and ['name','total','handled','ratio','response_ratio','handled_average','hold_average','response_average','responded'].include?(params[:orderby]))
			@orderby = params[:orderby]
		else 
			@orderby = 'name'
		end
	
		@userlist = User.find(:all, :select => "DISTINCT users.*", :joins => [:roles], :conditions => "role_id IN (3,4,5,6)", :order => "last_name #{@sortorder.upcase}")
    assignee_hash={:group_by_id => true, :dateinterval => @dateinterval, :limit_to_handler_ids => @userlist.map(&:id),:submitted_question_filter => @filteroptions.merge({:notrejected => true})}
    
		# this will get assigned, handled, and the ratio - assigned could be actual # of assignments minus 1 if the person is currently assigned something
	  handlingcounts = User.aae_handling_event_count(assignee_hash) 
	  responsecounts = User.aae_response_event_count(assignee_hash) 
		handlingaverages = User.aae_handling_average(assignee_hash)  
		holdaverages = User.aae_hold_average(assignee_hash)  
		responseaverages = User.aae_response_average(assignee_hash)  
		# let's merge this together
		@display_list = []
		@userlist.each do |u|
			values = {}
			values[:user] = u
			values[:total] = handlingcounts[u.id].nil? ? 0 : handlingcounts[u.id][:total]
			values[:handled] = handlingcounts[u.id].nil? ? 0 : handlingcounts[u.id][:handled]
			values[:ratio] = handlingcounts[u.id].nil? ? 0 : handlingcounts[u.id][:ratio]
			values[:handled_average] = handlingaverages[u.id].nil? ? 0 : handlingaverages[u.id]
			values[:responded] = responsecounts[u.id].nil? ? 0 : responsecounts[u.id][:responded]
			values[:response_ratio] = responsecounts[u.id].nil? ? 0 : responsecounts[u.id][:ratio]
			values[:response_average] = responseaverages[u.id].nil? ? 0 : responseaverages[u.id]
			values[:hold_average] = holdaverages[u.id].nil? ? 0 : holdaverages[u.id]
			@display_list << values
		end
	
		# now sort it, if the orderby is name, don't bother, it's already sorted from the mysql query
		if(@orderby != 'name')
			@display_list = ((@sortorder == 'asc') ? @display_list.sort!{|a,b| a[@orderby.to_sym] <=> b[@orderby.to_sym]} : @display_list.sort!{|a,b| b[@orderby.to_sym] <=> a[@orderby.to_sym]})
		end	
	end
 
	def nonassignee
	  # What is different about this report than the one above is that this one is counting responses of people who handled or responded
	  # who were *not* assigned to do so in the first place.
	     
		# validate dates
		@earliest_date = SubmittedQuestion.find_earliest_record.created_at.to_date
		@latest_date = Date.today
		@dateinterval = validate_datepicker({:earliest_date => @earliest_date, :default_datefrom => @earliest_date, :latest_date => @latest_date, :default_dateto => @latest_date})           
    
		# aae filter routines
		# TODO: simplify!!
		list_view
		set_filters    #pick up filters set in aae
		filter_string_helper
		@filteroptions = {:category => @category, :location => @location, :county => @county, :source => @source}
   
		#get list of assignee users  (expertise users)
		# Roles (id,name)
		# 1,Administrator
		# 2,Community Administrator
		# 3,Uncategorized Question Wrangler
		# 4,Auto Route Questions
		# 5,Receive Escalations
		# 6,Auto Route Widget Questions

		# sortorder
		if(params[:sortorder] and ['d','descending','desc'].include?(params[:sortorder].downcase))
			@sortorder = 'desc'
		else
			@sortorder = 'asc'
		end
		
		if(params[:orderby] and ['name','total','handled','ratio','response_ratio','handled_average','hold_average','response_average','responded'].include?(params[:orderby]))
			@orderby = params[:orderby]
		else 
			@orderby = 'name'
		end
	
		@userlist = User.find(:all, :select => "DISTINCT users.*", :joins => [:roles], :conditions => "role_id IN (3,4,5,6)", :order => "last_name #{@sortorder.upcase}")
    nonassignee_hash={:group_by_id => true, :dateinterval => @dateinterval, :limit_to_handler_ids => @userlist.map(&:id),:submitted_question_filter => @filteroptions.merge({:notrejected => true})}
    
		# this will get counts for handled and responded without being assigned first, handling average refers only to the time someone took to handle something if they did assign it to themselves
		# without being assigned first by someone else. Response averages are an approximation, calculated from last event.
	  handlingcounts = User.aae_nonassigned_handling_event_count(nonassignee_hash)  
	  responsecounts = User.aae_nonassigned_response_event_count(nonassignee_hash)    
		handlingaverages = User.aae_nonassigned_handling_average(nonassignee_hash)        
   	responseaverages = User.aae_nonassigned_response_average(nonassignee_hash)  
		# let's merge this together
		@display_list = []
		@userlist.each do |u|
			values = {}
			values[:user] = u
			values[:handled] = handlingcounts[u.id].nil? ? 0 : handlingcounts[u.id][:handled]
			values[:handled_average] = handlingaverages[u.id].nil? ? 0 : handlingaverages[u.id]
			values[:responded] = responsecounts[u.id].nil? ? 0 : responsecounts[u.id][:responded]
	  	values[:response_average] = responseaverages[u.id].nil? ? 0 : responseaverages[u.id]

			@display_list << values
		end
	
		# now sort it, if the orderby is name, don't bother, it's already sorted from the mysql query
		if(@orderby != 'name')
			@display_list = ((@sortorder == 'asc') ? @display_list.sort!{|a,b| a[@orderby.to_sym] <=> b[@orderby.to_sym]} : @display_list.sort!{|a,b| b[@orderby.to_sym] <=> a[@orderby.to_sym]})
		end	
	end

    private 

    def setup_routers_and_wranglers
      @question_wrangler_ids = User.question_wranglers.map{|qw| qw.id}
      @auto_router_ids = User.auto_routers.map{|ar| ar.id}
    end   
      
end
