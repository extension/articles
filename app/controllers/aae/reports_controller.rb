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
       (@date1,@date2, @dateFrom,@dateTo)= valid_date("dateFrom", "dateTo")
       (@date1,@date2,@dateFrom,@dateTo)= errchk(@date1,@date2,@dateFrom,@dateTo)
       @oldest_date = SubmittedQuestion.find_earliest_record.created_at.to_date
       @new= 0; @answ = 0; @resolved=0; @rej = 0; @noexprtse=0
       @rept = Aaereport.new(:name => "Activity")
       @repaction = "activity"
       @cats = Category.find(:all, :order => 'name')
    end

     def state_univ_activity
      @typelist = [];  @new={}; @reslvd={}; @answ={}; @rej={}; @noexp={} ; openquestions={}
        @type = params[:type]; @oldest_date = SubmittedQuestion.find_earliest_record.created_at.to_date
        (@date1, @date2, @dateFrom, @dateTo)=parmcheck(:FromDate, :ToDate, :from, :to, :dateFrom, :dateTo)   #parmcheck()
        if (@type=="State")
          @typelist  = Location.find(:all, :order => "entrytype, name")
        end
          typel= @type.downcase
         @rept = Aaereport.new({:name => "ActivityGroup", :filters => {:g => typel, :date1 => @date1, :date2 => @date2}})
         
         if @type=="State"
          openquestions = (@rept.NewQuestion({},[]))[0] 
         end
          resolved = (@rept.ResolvedQuestion({},[]))[0]
          answered = (@rept.ResolvedQuestion({ :status_state => SubmittedQuestion::STATUS_RESOLVED},[]))[0]
          rejected = (@rept.ResolvedQuestion({ :status_state => SubmittedQuestion::STATUS_REJECTED},[]))[0]
          noexp = (@rept.ResolvedQuestion({:status_state => SubmittedQuestion::STATUS_NO_ANSWER},[]))[0]
            stuv = nil
             @typelist.each do |st|
               if (@type=="State"); stuv= st.id; else; stuv=st.id.to_s; end;
                @new[st.name]= openquestions[stuv]
                @reslvd[st.name] = resolved[stuv]
                @answ[st.name] = answered[stuv]
                @rej[st.name] = rejected[stuv]
                @noexp[st.name] = noexp[stuv]
              end
          @repaction = "activity_by_#{typel}"
      end
      
      
    def common_display
       state_univ_activity
       params[:sdir]="a"
       @typelist = transform_typelist(@typelist)
       render :template=>'aae/reports/common_sorted_lists'
    end

    def activity_by_state
      # thoughts..
      # what does it mean if someone selects state and univ? people who belong to both states and univs? is this NC subdivided by NC State and NC A&T, for example?
      # what does it mean if someone selects state and tags? a subdivision of states with category entries? or vice versa? How do we allow them to do the vice-versa?
      # what does it mean if someone selects univ and tags? a subdivision of univs with category entries? or vice versa? How do we allow them to do the vice-versa?
      # obviously these are more complicated summary reports.  Or, could start with state, univ, tags and then allow, on the
      # display screen under where they choose the date, to select 1 of the other two, which would result in one entry on the next page for the combination
       params[:type]="State"
       common_display
     end

      def transform_typelist(typl)
         nar = []; typl.map { |nm| nar << [nm.name] } 
         nar
       end  
       
       def show_active_cats
         @filteredparams = FilterParams.new(params)  #can this be useful here? for hackers of the url? filter by location as well...
          @filteredoptions = @filteredparams.findoptions
           @typename = params[:category] ;  @locid = nil; @statename=nil ; @locname=nil ; @filtstr=""    #was :Category
           @statename = params[:State]    #in case someone hacks in &State=NY...use abbreviation
           if (loc=Location.find_by_id(params[:location]))  #in case someone hacks in &location=n...
                @locname = "#{loc.id} (" + loc.name + ")"
                @locid = loc.id
                if (@statename && loc.abbreviation != @statename  && loc.name != @statename)   ##someone typed in both and they don't match
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
           @filteredoptions.merge!({:location => Location.find_by_id(@locid)}) if (@locid && !params[:location])  ##should probably add :State into the FilterParams wantsparameter lists
            cat = Category.find_by_name(@typename); ((@locid) ? @filtstr = "Filtered by Location= #{@locname}" : "") 
            @type = "Category" ; @typel="category"; @typet="Tag"
            @oldest_date = SubmittedQuestion.find_earliest_record.created_at.to_date; 
           (@date1, @date2, @dateFrom, @dateTo)=parmcheck(:FromDate, :ToDate, :from, :to, :dateFrom, :dateTo)  #parmcheck()
            @typelist = [cat]
            if !cat.nil?
                #tagname = Tag.normalize_tag(cat.name)
                @rept = Aaereport.new({:name => "ActivityCategory", :filters => @filteredoptions})
                @repaction = "show_active_cats" 
                render :template=>'aae/reports/common_lists'
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
       
       def common_sort_columns
           typ = params[:type]; fld = params[:field] ; sortdir = params[:sdir]; report = params[:report]; params[:bysort]="y"
            if fld == 'State'   #get the original summary back
                if typ == 'Assignee'
                  self.send(report.intern)
                  render :template => 'aae/reports/assignee'
                else
                  self.send((report+"_by_#{typ.downcase}").intern)
                end
            else
              case typ    #remake the variable lists 
                when 'Institution', 'State'
                  self.send(("state_univ_"+report).intern)
                when 'Assignee'
                  self.send(report.intern)
                else
                  self.send(("#{typ.downcase}_"+report).intern)
              end
              rus = Array.new; russ = Array.new
              rus =  instance_variable_get("@" + fld).find_all { |k,v| k!= "ZZ"}  #turn remade lists into a sortable array
              if sortdir=="d"
                   russ = rus.sort { |a,b| ((b[1]) ? b[1] : 0) <=> ((a[1]) ? a[1] : 0)}    #sort in desc order of totals
              else
                   russ = rus.sort { |a,b| ((a[1]) ? a[1] : 0) <=> ((b[1]) ? b[1] : 0)}    #sort in asc order of totals
              end
              if fld=='avgchg' || fld[0..2]=='ppd'
                russ = siftna(russ)
              end
              @typelist = russ
              case report
              when 'activity'
                 render :template=>'aae/reports/common_sorted_lists'
              when 'response_times'
                 render :template => 'aae/reports/common_resptimes_lists'
              when 'assignee'
                 render :template => 'aae/reports/assignee'
              end
           end
       end
       
        def order_clause(order_by = "sq.question_updated_at", sort = "desc")
           if !params[:ob].nil?
             order_by = params[:ob]
             if params[:ob] == "id"
               order_by = "sq.id"
             elsif params[:ob] == "squpdated"
               order_by = " sq.updated_at"
             elsif params[:ob] == "sqid"
               order_by = "sq.id"
             end
           end

           if params[:so] and params[:so] == 'a'
             sort = "asc"
           end

           order_clause = order_by + " " + sort

         end

        def display_tag_links
            @cat = Category.find_by_name(params[:category])
            @olink = params[:olink]; @comments=nil; @edits=params[:descriptor]; @idtype='sqid'
             aux = nil ; @catname = params[:category]; locid = params[:locid]
            @dateFrom = params[:from] ;  @dateTo=params[:to]
             @date1 = date_valid(@dateFrom) ; @date2 = date_valid(@dateTo)
            desc = params[:descriptor]; @numb = params[:num].to_i
             if (@edits.length > 8)
               if (@edits[0..7]=="Resolved")
                 aux = @edits[8].chr
                 @edits = "Resolved"
               end
             end
              select_string = " sq.id squid, sq.updated_at updated_at, resolved_by, asked_question, sq.question_updated_at, sq.status_state status"
              jstring = " as sq join categories_submitted_questions as csq on csq.submitted_question_id=sq.id " + ((locid) ? " join locations on sq.location_id=locations.id " : "")
              (desc=="New") ? @pgt = " Newly Submitted Questions in '#{@cat.name}'  " : @pgt = " Questions Resolved from Ask an Expert for '#{@cat.name}'"
              (params[:locname]) ? @filtstr = "Filtered by Location = #{params[:locname]} "  : ""
              
              @questions = SubmittedQuestion.find_questions(@cat, @edits, aux, locid,  @date1, @date2,
                 :all,  :select => select_string,  :joins => jstring, :order => order_clause("sq.updated_at", "desc"),
                       :page => params[:page], :per_page => AppConfig.configtable['items_per_page'])                                                
              @min = 124
             render  :template => "aae/reports/display_questions"
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
         if (params[:from] && params[:to])
            @dateFrom = params[:from] ;  @dateTo=params[:to]
            @date1 = date_valid(@dateFrom) ; @date2 = date_valid(@dateTo)
          else
            (@date1,@date2,@dateFrom,@dateTo)=valid_date("dateFrom", "dateTo")
            (@date1,@date2,@dateFrom,@dateTo)= errchk(@date1,@date2,@dateFrom,@dateTo)
          end
          @oldest_date = SubmittedQuestion.find_earliest_record.created_at.to_date
          @user = User.find_by_id(params[:id]) 
          if @user
            @uresolved = @user.resolved_questions.date_subs(@date1, @date2).count(:conditions => "status_state in (#{SubmittedQuestion::STATUS_RESOLVED}, #{SubmittedQuestion::STATUS_REJECTED}, #{SubmittedQuestion::STATUS_NO_ANSWER})")
            @uassigned = @user.ever_assigned_questions(@date1,@date2, nil, nil).count
            @avgstdresults = @user.get_avg_resp_time(@date1, @date2)
           end
       #   @myid = @currentuser
          if @user.nil? #|| @myid.nil?
            redirect_to :controller => 'reports', :action => 'user_report'
          end
          @repaction = "user"
        end
        
        def display_questions
           @user = User.find_by_id(params[:user]);
           @olink = params[:olink];  @comments=nil; @edits=nil; 
           @dateFrom = params[:from] ;  @dateTo=params[:to]
           @date1 = date_valid(@dateFrom) ; @date2 = date_valid(@dateTo)
           desc = params[:descriptor]; @numb = params[:num].to_i; join_string = ""; group_name = nil
           descl = desc

             select_string = " sq.current_contributing_question question_id, sq.user_id, sq.id squid,  resolved_by, " +
                " sq.status_state status, sq.created_at, sq.updated_at updated_at, asked_question " 
           if desc=="Assigned as an Expert"
             select_string = select_string + " , recipient_id "
             join_string = " join submitted_question_events on sq.id=submitted_question_events.submitted_question_id "
             group_name = "submitted_question_id"
             descl = "was Assigned as an Expert"
           end
            
             @pgt = "Questions #{@user.first_name} #{@user.last_name} #{descl} "
             @faq = nil; @idtype='sqid'
        
        
             @questions = SubmittedQuestion.find_questions(@user, desc,nil,nil, @date1, @date2,
                                                            :all,
                                                            :select => select_string,
                                                            :joins => " as sq #{join_string} ",
                                                            :order => order_clause("sq.updated_at", "desc"),
                                                            :group => group_name,
                                                            :page => params[:page],
                                                            :per_page => AppConfig.configtable['items_per_page'])
    

         #   set_navigation_context('list', @questions, 'reports')

        end
        
        ####   end of User Report for Ask an Expert Activity #####
         
         ####  Date handling ###
         
         
   
           def valid_date(fromdate, todate)               #valid_date() with date(c)From and date(c)To
             dateFrom = params[fromdate] if (params[fromdate] ) 
             date1 = date_valid(dateFrom)
             dateTo = params[todate] if (params[todate] )
             date2 = date_valid(dateTo)
             [date1, date2, dateFrom, dateTo]
           end


          def date_valid(yyyymmdd)
              #yyyymmdd = yyyy-mm-dd
              return nil if !yyyymmdd || yyyymmdd=="" 
              begin
                t =  Time.parse(yyyymmdd)
              rescue Exception => e
                 flash.now[:failure] = "Incorrect input detected: #{yyyymmdd}, do yyyy-mm-dd "
                 ActiveRecord::Base::logger.debug "time parse error on #{yyyymmdd} "  + e.to_s
                 return nil
              end
              return t
          end 

          def errchk(datef,datet, dateFrom, dateTo)
           if ((datef && datet) && (datet - datef < 0))
              #   flash.now[:notice] = "From Date is not before To Date."
                temp =datet; tmps = dateTo    #if flipped, flip 'em
                datet = datef; dateTo = dateFrom
                datef = temp; dateFrom = tmps
           end
          [datef, datet, dateFrom, dateTo]
          end

          def parmcheck(fromdate, todate, from, to, dateF, dateT)     #parmcheck() ...check all date parms   (c) means compare_dates parms
              if params[:bysort] !="y"
                if params[fromdate]      #:From(c)Date
                  dateFrom = params[fromdate]
                else
                    dateFrom = params[dateF] if (params[dateF] )    #:date(c)From
                end
                date1 = date_valid(dateFrom)
                if params[todate]         #:To(c)Date
                  dateTo=params[todate]
                else
                   dateTo = params[dateT] if (params[dateT] )      #:date(c)To
                end
                date2 = date_valid(dateTo)
              else
                dateFrom = params[from]      #:from(c)
                dateTo=params[to]            #:to(c)
                date1 = date_valid(dateFrom)
                date2 = date_valid(dateTo)
              end

              (date1, date2, dateFrom, dateTo)= errchk(date1,date2,dateFrom,dateTo)
              [date1, date2, dateFrom, dateTo]
          end    


         ##### end date handling ##### 
        
        ## Expertise Report
        def answerers
         @cats = Category.find(:all, :conditions => "parent_id is null", :order => 'name')
         @csize = @cats.size
         @catcnt = Category.count_users_for_rootcats
         @locs = ExpertiseLocation.find(:all, :order => 'entrytype, name')
         @lsize = @locs.size 
         #@locsum=ExpertiseLocation.count_answerers_by_state
         @locsum = ExpertiseLocation.count(:joins => " join expertise_locations_users as elu on expertise_locations.id=elu.expertise_location_id join users on users.id=elu.user_id",
                 :group => "elu.expertise_location_id", :order => "entrytype, name")
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
              @catname=params[:category]
              catid = Category.find_by_name(@catname).id
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
        #    @filterstring = @filteredparams.filter_string   ...why do I need this?
             @cats = Category.find(:all, :conditions => "parent_id is null", :order => "name")
             @csize = @cats.size 
             @cnties = ExpertiseCounty.find(:all,  :conditions => "expertise_location_id = #{params[:location]}", :order => 'countycode, name').collect { |nm| [nm.name, nm.id]}       
             @ysize = @cnties.size
           #  @locations = ExpertiseCounty.filtered(@findoptions).displaylist
             @catcnt = Category.catuserfilter_count(@filteredoptions)
             @cntycnt = ExpertiseCounty.expert_county_userfilter_count(@filteredoptions)
             
             @user_list = ExpertiseLocation.find_by_id(params[:location]).users.find(:all, :order => "users.last_name")
             setup_routers_and_wranglers
             
             @usize = @user_list.size ; @locid = params[:location]
             @statename = ExpertiseLocation.find_by_id(params[:location]).name
             
              # heureka's way....translated to darmok, that works
       #   if params[:State]
      #      @statename = params[:State]
      #    end
      #    if (@statename && @statename != "")
      #       @cats = Category.find(:all, :conditions => "parent_id is null", :order => 'name')
      #       @csize = @cats.size
      #       @catcnt = Category.count_users_for_rootcats_in_state(@statename)
      #       @cnties = ExpertiseCounty.find(:all,  :conditions => "location_id = #{ExpertiseLocation.find_by_name(@statename).id}", :order => 'countycode, name').collect { |nm| [nm.name, nm.id]}       
      #       @ysize = @cnties.size
      #     #  @cntycnt = County.count_answerers_for_county(@statename)
      #       @cntycnt = ExpertiseCounty.count(:all,:select => "ecu.user_id", :joins => " join expertise_counties_users as ecu on ecu.expertise_county_id=expertise_counties.id " + 
      #          "join users on ecu.user_id=users.id join expertise_areas as ea on ecu.user_id=ea.user_id join categories as c on ea.category_id=c.id",
      #          :conditions =>  ["expertise_counties.expertise_location_id=? and c.parent_id is null", ExpertiseLocation.find_by_name(@statename).id],
      #          :group => "expertise_counties.name", :distinct => "true")
      #          
      #      #  userlist = ExpertiseLocation.find_by_sql(["Select distinct users.id, users.first_name, users.last_name, users.login, roles.name, roles.id as rid from expertise_locations join expertise_locations_users as lu on lu.expertise_location_id=expertise_locations.id " +
      #               "  join users on lu.user_id=users.id left join user_roles on users.id=user_roles.user_id left join roles on user_roles.role_id=roles.id " +
      #               " where expertise_locations.id=? order by users.last_name",ExpertiseLocation.find_by_name(@statename).id ])
      #      @userlist = consolidate(ExpertiseLocation.get_users_in_state(@statename))
      #        @userlist = consolidate(userlist)
      #       @usize = @userlist.size
      #   end
        end

        def category_users
           @filteredparams=FilterParams.new(params)
           @filteredoptions = @filteredparams.findoptions
          if params[:State]
             @statename = params[:State]
             @locid = ExpertiseLocation.find_by_name(@statename)
          end
          if params[:County]
            @county = params[:County]
          end
          if (@statename && @county && @statename != "" && @county != "")
             @cats = Category.find(:all, :conditions => "parent_id is null ", :order => 'name')
             @csize = @cats.size
             @ctycnt = Category.catuserfilter_count(@filteredoptions)
             
             @user_list = ExpertiseCounty.find_by_id(params[:county]).users.find(:all, :order => "users.last_name")
             setup_routers_and_wranglers
             
             @usize = @user_list.size
          end
        end

        def category_county_users
          # todo -- need validation of county id, state id, and category - ATH
          
          if params[:State]
            @statename = params[:State]
            @locid = ExpertiseLocation.find_by_name(@statename)
          end
          if params[:County]
            @county = params[:County]
          end
          if params[:Category]
            @catname = params[:Category]
            category = Category.find_by_name(params[:Category])
          end
          if (@statename && @county && @catname && @statename !="" && @county != "" && @catname != "")
            @capcatname = @catname[0].chr.to_s.upcase + @catname[1..(@catname.length - 1)]
            countyid = ExpertiseCounty.find(:first, :conditions => ["expertise_location_id=#{ExpertiseLocation.find_by_name(@statename).id} and name=?", @county]).id
            
            @user_list = User.experts_by_county(ExpertiseCounty.find_by_name(params[:County])).routers_by_category(category.id)  
            setup_routers_and_wranglers
          
            @usize = @user_list.size
          end
        end

        def county_answerers
          # todo -- need validation of county id, state id, and category - ATH
          
          if params[:id]
             @statename = ExpertiseLocation.find_by_id(params[:id]).name
             @locid = params[:id]
          else
            if params[:State]
              @statename = params[:State]
              @locid = ExpertiseLocation.find_by_name(@statename).id
            end
          end
          @catname = params[:Category]
          if (!@catname || @catname == "")
              redirect_to :action => 'answerers'
          end
          
          category = Category.find_by_name(params[:Category])
          
          if params[:dir]
            @dir = params[:dir]
          end
          if (@statename && @statename != "")
            @cnties = ExpertiseCounty.find(:all,  :conditions => "expertise_location_id = #{Location.find_by_name(@statename).id}", :order => 'countycode, name').collect { |nm| [nm.name, nm.id]}
            @cntycnt = ExpertiseCounty.count_answerers_for_county_and_category(@catname, @statename)
            @capcatname = @catname[0].chr.to_s.upcase + @catname[1..(@catname.length - 1)]
            
            @user_list = User.experts_by_location(ExpertiseLocation.find_by_id(@locid)).routers_by_category(category.id)
            setup_routers_and_wranglers
            
            @csize = @cnties.size
            @usize = @user_list.size
          else
            redirect_to :action => 'state_answerers', :Category => @catname
          end  
        end

        def answerers_lists
          # todo -- need validation of county id, state id, and category - ATH
          
          @statename = params[:State]
          @catname = params[:Category]
          @county = params[:County]
          if params[:dir]
            @dir=params[:dir]
          end
          if (!@catname || @catname=="")
            redirect_to :action => 'answerers'
          end
          
          category = Category.find_by_name(params[:Category])
          
          if (!@statename || @statename =="") 
            redirect_to :action => 'state_answerers', :Category => @catname
          end
          if (@county)
            countyid = ExpertiseCounty.find(:first, :conditions => ["expertise_location_id=#{ExpertiseLocation.find_by_name(@statename).id} and name=?", @county]).id
            @capcatname = @catname[0].chr.to_s.upcase + @catname[1..(@catname.length - 1)]
          # form array of users for selected county
        
            @user_list = User.experts_by_county(ExpertiseCounty.find_by_id(countyid)).routers_by_category(category.id)
            setup_routers_and_wranglers
            
            @usize = @user_list.size
          else
            redirect_to :action => 'county_answerers', :State => @statename, :Category => @catname
          end
        end
        
    ##  End of Expertise Report
    
    
    ####   State Report for Ask an Expert  #####
    
    def state_report

    end
    
    
    def show_all_by_state
       if (params[:from] && params[:to])
         @dateFrom = params[:from] ;  @dateTo=params[:to]
          @date1 = date_valid(@dateFrom) ; @date2 = date_valid(@dateTo)
       else
         (@date1,@date2,@dateFrom,@dateTo)=valid_date("dateFrom", "dateTo")
         (@date1,@date2,@dateFrom,@dateTo)= errchk(@date1,@date2,@dateFrom,@dateTo)
       end
       @typename = params[:State]; 
       if (@typename && @typename != "") 
         @typeobj = Location.find_by_name(params[:State]) 
         @type = "State" ; @typel="state" ;  @oldest_date = SubmittedQuestion.find_earliest_record.created_at.to_date
         locabbr=@typeobj.abbreviation; locid = @typeobj.id
     
         if !@typeobj.nil?  
      
           @reguser = User.date_users(@date1, @date2).count(:conditions => "location_id=#{locid}")
        
           @asgn = SubmittedQuestion.date_subs(@date1, @date2).count(:conditions =>  " status_state=#{SubmittedQuestion::STATUS_SUBMITTED} and location_id=#{@typeobj.id}")
           (@answp, @answpa, @answpr, @answpn)= SubmittedQuestion.get_answered_question_by_state_persp("pertaining",@typeobj, @date1, @date2)
           (@answm, @answma, @answmr, @answmn)= SubmittedQuestion.get_answered_question_by_state_persp("member", @typeobj, @date1, @date2)
       
           @repaction = "show_all_by_state"      
           render :template=>'aae/reports/state'

         else
           redirect_to :controller => 'aae/reports', :action => 'state_report'
         end
       else
         redirect_to :controller => 'aae/reports', :action => 'index'
       end
     end
     
     def display_state_links
         @type = params[:type]
         if (@type == 'State')
            @loc = Location.find_by_id(params[:loc]); @county = nil; @typename = @loc.name; @statename = @loc.name
         else
            @loc = Location.find_by_name(params[:State]) ; @county = params[:County]; @typename = @county ; @statename = params[:State]
         end
         @olink = params[:olink]; @comments=nil;  @edits=params[:descriptor]; @numb = params[:num].to_i
         if (@edits.length > 9)
           if (@edits[0..7]=="Resolved")
             @edits = @edits[0..8]
           end
         end
         @dateFrom = params[:from] ;  @dateTo=params[:to] ; @oldest_date = SubmittedQuestion.find_earliest_record.created_at.to_date
         @date1 = date_valid(@dateFrom) ; @date2 = date_valid(@dateTo)
         
         @limit_string = "Only up to 100 are shown."
        
         
             (@edits[0..7]== "Resolved") ?  jrestring = " join users on sq.resolved_by=users.id " :  jrestring=""
             select_string = "sq.user_id, sq.id squid, resolved_by, sq.location_id, current_contributing_question question_id,  " +
                " sq.status_state status, sq.created_at, sq.updated_at updated_at, asked_question " 
            
              jstring= " as sq #{jrestring}"
             if @edits == 'Submitted'
               @pgt = "Submitted Questions pertaining to #{@typename}"
             else
               (@edits[8].chr=="P") ? @pgt = "Resolved Questions pertaining to #{@typename}" : @pgt="Questions Resolved by a member in #{@typename}" 
             end
             @faq = nil; @idtype = 'sqid'  
        

                 
           @questions = SubmittedQuestion.find_state_questions(@loc, @county, params[:descriptor], @date1, @date2,
                        :all,
                        :select =>select_string,
                        :joins => jstring,
                        :order => (@edits=="Submitted" || @edits[0..7]=="Resolved") ? order_clause("sq.updated_at", "desc") : order_clause,
                        :page => params[:page],
                        :per_page => AppConfig.configtable['items_per_page'])
         
         
          @pgtl = @pgt
          if (@type=='County')
            @pgtl = @pgt + " county/parish in #{@loc.name}"
          end
      #    set_navigation_context('list', @questions, 'reports')
          @min = 124
          render  :template => "aae/reports/display_questions"
      end

      def display_state_users
         @type = params[:type]
         if (@type == 'State')
           @loc = Location.find_by_id(params[:loc]); @county = nil; @typename = @loc.name
         else
           @loc = Location.find_by_name(params[:State]); @county = params[:County]; @typename = @county
         end
         @olink = params[:olink]; @comments=nil; @edits=params[:descriptor]; @numb = params[:num].to_i
         @dateFrom = params[:from] ;  @dateTo=params[:to] ;
         @date1 = date_valid(@dateFrom) ; @date2 = date_valid(@dateTo)
         @users=User.find_state_users(@loc, @county, @date1, @date2,
           :all, :select => " id, first_name, last_name, login, email, institution_id, county_id", :order => "last_name", :page => params[:page], :per_page => AppConfig.configtable['items_per_page'])

      end
     
     
      ####  County Report for Ask an Expert ####

     def county_select
       @date1=nil; @date2=nil; @dateFrom=nil; @dateTo=nil
       if (params[:from] && params[:to])
         @dateFrom = params[:from] ;  @dateTo=params[:to]
         @date1 = date_valid(@dateFrom) ; @date2 = date_valid(@dateTo)
       end
       if params[:State]
           @statename = params[:State]
       end
       if (@statename && @statename != "")
         @counties= County.find(:all,  :conditions => "location_id = #{Location.find_by_name(@statename).id} and name<>'All'", :order => 'countycode, name')
       else
         redirect_to :controller => 'aae/reports', :action => 'index'
       end
     end


     def county
       if (params[:from] && params[:to])
         @dateFrom = params[:from] ;  @dateTo=params[:to]
         @date1 = date_valid(@dateFrom) ; @date2 = date_valid(@dateTo)
       else
         (@date1,@date2,@dateFrom,@dateTo)=valid_date("dateFrom", "dateTo")
         (@date1,@date2,@dateFrom,@dateTo)= errchk(@date1,@date2,@dateFrom,@dateTo)
       end
       @county = params[:County]; @typename = @county
       @statename=params[:State]
       if (@county && @statename && @statename!="")
         loc=Location.find_by_name(@statename) 
         locabbr = loc.abbreviation
        
         @typeobj = County.find(:first, :conditions => ["location_id= ? and name= ?", loc.id, @county])
         @type="County"; @typel="county" ;   @oldest_date = SubmittedQuestion.find_earliest_record.created_at.to_date
         if !@typeobj.nil? 
       
           @reguser = User.date_users(@date1, @date2).count(:conditions => "county_id = #{@typeobj.id}")
         
          @asgn = SubmittedQuestion.date_subs(@date1, @date2).count(:conditions =>  " status_state=#{SubmittedQuestion::STATUS_SUBMITTED} and county_id=#{@typeobj.id}")
          (@answp, @answpa, @answpr, @answpn)= SubmittedQuestion.get_answered_question_by_county_persp("pertaining",@typeobj, @date1, @date2)
          (@answm, @answma, @answmr, @answmn)= SubmittedQuestion.get_answered_question_by_county_persp("member",@typeobj, @date1, @date2)   
          
           @repaction = 'county'
           render :template => 'aae/reports/state'
        else
          redirect_to :controller => 'aae/reports', :action => 'county_select', :State => @statename
        end
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
           (public1, widget1)= response_checkbox_setup(:dateTo, :public_sourcea, :widget_sourcea, :via_conduita)
           #Retain other part of page and modify this section as appropriate
           @date1 = params[:dat1]; @date2 = params[:dat2]; @dateFrom = params[:datF]; @dateTo=params[:datT]
            if params[:dateTo]
               @first_set="y"
               if params[:commit]=="Clear" || params[:commit]=="Show all" || params[:commit]=="Last 90 days"
                 @clear1 = "y"
               end
            end
            if !@date1 && @clear1=="n"
              if (repaction=='response_times_by_category' || repaction=='response_times_by_location')
                (@date1, @date2, @dateFrom, @dateTo) = parmcheck(:FromDate, :ToDate, :from, :to, :dateFrom, :dateTo)
              else
                (@date1,@date2,@dateFrom,@dateTo)=valid_date("dateFrom", "dateTo")
                (@date1,@date2,@dateFrom,@dateTo)= errchk(@date1,@date2,@dateFrom,@dateTo)
              end
              if (@date1 && @date2)
                @unselected=nil
                @nodays=(@date2.to_i - @date1.to_i)/(3600*24) 
                if @nodays > 30 ; @nodays=30; end
              end
            else
              if @clear1 != "y"
                @date1 = date_valid(@dateFrom); @date2 = date_valid(@dateTo)
                if (@date1 && @date2)
                  @unselected=nil
                  @nodays=(@date2.to_i - @date1.to_i)/(3600*24.0) 
                  if @nodays > 30 ; @nodays=30; end
                end
              else
                @date1 = nil; @unselected="y"
              end
            end
           [@date1, @date2, public1, widget1, @nodays]
     end      

     def response_avgs_upper(public1, widget1)
            @number_questions = SubmittedQuestion.find_once_externally_submitted(@date1, @date2, public1, widget1)
            @avg_response_time = SubmittedQuestion.get_avg_response_time(@date1, @date2, public1, widget1)
            @avg_resp_past30 = SubmittedQuestion.get_avg_response_time_past30(@date1, @date2, public1, widget1, @nodays)
            @avg_still_open = SubmittedQuestion.find_externally_submitted(@date1, @date2, public1, widget1)
            if (params[:dateTo])
                 session[:first_set]= "y"
            end
     end

     def response_dates_lower(repaction)
        #make sure we read what was last in the checkboxes and retain it
        (public2, widget2) = response_checkbox_setup(:datecTo, :public_sourceb, :widget_sourceb, :via_conduitb)
        if params[:datecTo]
          @sec_set="y"
          if params[:commit]=="Clear" || params[:commit]=="Show all" || params[:commit]=="remove"
            @clear2 = "y"
          end
         end
        #retain fields from upper as we change the lower as appropriate
         @datec1 = params[:compd1]; @datec2=params[:compd2] ; @datecTo = params[:compds]; @datecFrom = params[:compdf]
          if !@datec1 && @clear2=="n"
            if (repaction=='response_times_by_category' || repaction=='response_times_by_location')
               (@datec1, @datec2, @datecFrom, @datecTo) = parmcheck(:FromcDate, :TocDate, :fromc, :toc, :datecFrom, :datecTo)   #parmccheck
            else
              (@datec1,@datec2,@datecFrom,@datecTo)=valid_date("datecFrom", "datecTo")  
              (@datec1,@datec2,@datecFrom,@datecTo)= errchk(@datec1,@datec2,@datecFrom,@datecTo)
            end
            if (@datec1 && @datec2)
              @unselectedc=nil
              @nocdays=(@datec2.to_i - @datec1.to_i)/(3600*24.0) 
              if @nocdays >= 30 ; @nocdays=30; end
            end
          else
             if @clear2 != "y"
               @datec1 = date_valid(@datecFrom); @datec2 = date_valid(@datecTo)
                if (@datec1 && @datec2)
                   @unselectedc=nil
                   @nocdays=(@datec2.to_i - @datec1.to_i)/(3600*24.0) 
                   if @nocdays >= 30 ; @nocdays=30; end
                end
             else
               @datec1 = nil; @unselectedc="y"
             end
           end
          [@datec1, @datec2, public2, widget2, @nocdays]
     end

     def response_avgs_lower(public2, widget2)
         @numbc_questions = SubmittedQuestion.find_once_externally_submitted(@datec1, @datec2, public2, widget2)
         @avgc_response_time = SubmittedQuestion.get_avg_response_time(@datec1, @datec2, public2, widget2)
         @avgc_resp_past30 = SubmittedQuestion.get_avg_response_time_past30(@datec1, @datec2, public2, widget2, @nocdays)
         @avgc_still_open = SubmittedQuestion.find_externally_submitted(@datec1, @datec2, public2, widget2)
          if (params[:datecTo])
               session[:sec_set]= "y"
          end
     end


     def response_times
       @sec_set = nil; @first_set= nil; @clear1="n"; @clear2="n"
       @first_set = session[:first_set] if session[:first_set]
       @sec_set = session[:sec_set] if session[:sec_set]
       @oldest_date = SubmittedQuestion.find_earliest_record.created_at.to_date
       @repaction = 'response_times'
       @nodays = 30; @nocdays = 30
       @number_questions_all = SubmittedQuestion.find_externally_submitted(nil, nil, true, true )
       @avg_response_time_all = SubmittedQuestion.get_avg_response_time(nil, nil, true, true)
       @avg_resp_past30_all = SubmittedQuestion.get_avg_response_time_past30(nil, nil, true, true, @nodays)
       @avg_open_time_all = SubmittedQuestion.get_avg_open_time(nil, nil,nil, true, true)
       (@date1, @date2, public1, widget1, @nodays)=response_dates_upper(@repaction)
       response_avgs_upper(public1, widget1)
       (@datec1, @datec2, public2, widget2, @nocdays) = response_dates_lower(@repaction)
       response_avgs_lower(public2, widget2)
     end  
    
    
    def get_responses_by_category(date1, date2, pub, wgt)
       extstr = SubmittedQuestion.get_extapp_qual(pub, wgt) ; avgrh = {}
       if extstr == " IS NULL";  return [ {}, {}, {}]; end
       noq = SubmittedQuestion.named_date_resp(date1, date2).count(:joins => [:categories], :conditions => " external_app_id #{extstr} ", :group => "category_id")
      # avgr = SubmittedQuestion.makehash(SubmittedQuestion.named_date_resp(date1, date2).count_avgs_cat(extstr), "category_id",1.0)
      avgr = (SubmittedQuestion.named_date_resp(date1, date2).count_avgs_cat(extstr)).map { |avgs| avgrh[avgs.category_id] = avgs.ra.to_f}
     #  avg30 = SubmittedQuestion.count_avg_past30_responses_by(date1, date2, pub, wgt, "category")
       noopen = SubmittedQuestion.named_date_resp(date1, date2).count(:joins => [:categories], :conditions => " status_state = #{SubmittedQuestion::STATUS_SUBMITTED} and external_app_id #{extstr} ", :group => 'category_id')
       # used to be [noq, avg4, avg30, noopen]
       [noq, avgr, noopen]
     end


     def category_response_times
       @typelist = []; @nof= {}; @var1={}; @var2={}; @var3={}
       @nos1={}; @nostopn1={}; @p301 = {}; @ppd1 = {}; @avgchg = {} ; @nos2={}; @nostopn2={}; @p302 = {}; @ppd2 = {}
       @first_set = nil; @sec_set= nil; @clear1="n"; @clear2="n"
       @first_set = session[:left_set] if session[:left_set]
       @sec_set = session[:right_set] if session[:right_set]
       t= Time.now - 90*24*60*60
       @prior90th = t.to_s
       @repaction = 'response_times_by_category'; @pagetype=" Category"; rslts = {}
        #set up defaults   #note, old avg_30_reponses once was in here...(no_questions, avg_responses, avg_30_responses, avg_waiting)
        (rslts[:no_questions],rslts[:avg_responses], rslts[:avg_waiting]) = get_responses_by_category(nil, nil, true, true)
           # deal with date data
         (@date1, @date2, public1, widget1, @nodays)=response_dates_upper(@repaction)
           # selected dates upper
           (rslts[:nos1_questions], rslts[:avg1_responses],rslts[:avg1_still_open])= get_responses_by_category(@date1, @date2, public1, widget1)
             if (params[:dateTo])
               session[:left_set]= "y"
             end
         (@datec1, @datec2, public2, widget2, @nocdays) = response_dates_lower(@repaction)
            # selected dates lower
            (rslts[:nos2_questions], rslts[:avg2_responses], rslts[:avg2_still_open])= get_responses_by_category(@datec1, @datec2,  public2, widget2)
            if (params[:datecTo])
              session[:right_set]= "y"
            end
       @type = "Category"
        @typelist= Category.find(:all,  :order => 'name')
        response_times_summary(rslts)
     end

     def response_times_by_category
        @unselected = "y"; @unselectedc="y"
        category_response_times
        params[:sdir]="a"
        @typelist = transform_typelist(@typelist)
        render :template=>'aae/reports/common_resptimes_lists'
     end

     def get_responses_by_location(date1, date2, pub, wgt)
       extstr = SubmittedQuestion.get_extapp_qual(pub, wgt) ; avgrh = {}
        if extstr == " IS NULL";  return [ {}, {}, {}]; end
       #  noq = SubmittedQuestion.named_date_resp(date1, date2).count(:joins => " join users on (submitted_questions.resolved_by=users.id or submitted_questions.user_id=users.id) ",
      #        :conditions =>  " external_app_id #{extstr} ", :group => "users.location_id")  ##THIS STATEMENT GOES TO NEVER_NEVER LAND
         noq = SubmittedQuestion.get_noq(date1, date2, extstr)    ##NOTE: THIS STATEMENT WILL SPLIT THE JOIN AND WORK
         avgr = SubmittedQuestion.makehash(SubmittedQuestion.named_date_resp(date1, date2).count_avgs_loc(extstr), "location_id",1.0)
       #  avgr = (SubmittedQuestion.named_date_resp(date1, date2).count_avgs_loc(extstr)).map { |avgs| avgrh[avgs.location_id] = avgs.ra.to_f}
       # avg30 = SubmittedQuestion.count_avg_past30_responses_by(date1, date2, pub, wgt, "location")
        
         noopen = SubmittedQuestion.named_date_resp(date1, date2).count(:joins => "join users on submitted_questions.user_id=users.id", 
              :conditions =>  " status_state=#{SubmittedQuestion::STATUS_SUBMITTED} and external_app_id #{extstr} ", :group => "users.location_id")
        # [noq, avgr, avg30, noopen]
        [noq, avgr, noopen]
      end

      def response_times_summary(results_hash)
        stuv = nil
        @typelist.each do |st|
           stuv = st.id
           @nof[st.name]= results_hash[:no_questions][stuv] ; @nos1[st.name]=@nof[st.name]
           @var1[st.name]= results_hash[:avg_responses][stuv]; @ppd1[st.name]= @var1[st.name]
        #   @var2[st.name]= avg_30_responses[st.abbreviation] 
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
         @prior90th = t.to_s; 
         @repaction = 'response_times_by_location' ; rslts={}
          #set up defaults   #note....(no_questions, avg_responses, avg_30_responses, avg_waiting)...old example
          (rslts[:no_questions],rslts[:avg_responses],rslts[:avg_waiting]) = get_responses_by_location(nil, nil,  true, true)
             # deal with date data
           (@date1, @date2, public1, widget1, @nodays)=response_dates_upper(@repaction)
             # selected dates upper
             (rslts[:nos1_questions], rslts[:avg1_responses], rslts[:avg1_still_open])= get_responses_by_location(@date1, @date2,  public1, widget1)
               if (params[:dateTo])
                 session[:set1]= "y"
               end
           (@datec1, @datec2, public2, widget2, @nocdays) = response_dates_lower(@repaction)
              # selected dates lower
              (rslts[:nos2_questions], rslts[:avg2_responses], rslts[:avg2_still_open])= get_responses_by_location(@datec1, @datec2,  public2, widget2)
              if (params[:datecTo])
                session[:set2]= "y"
              end
         @type = "Location"; @pagetype="Responder Location"
          @typelist= Location.find(:all,  :order => 'entrytype, name') 
          response_times_summary(rslts)
       end

       def response_times_by_location
          @unselected = "y"; @unselectedc="y"
          location_response_times
          params[:sdir]="a"
          @typelist = transform_typelist(@typelist)
          render :template=>'aae/reports/common_resptimes_lists'
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

       def display_discrete_responded
          @cat = Category.find_by_name(params[:cat]); @resolver=User.find_by_id(params[:id])
          @olink = params[:olink]; @comments=nil; @edits="Resolved"; @idtype='id'
          @dateFrom = params[:from] ;  @dateTo=params[:to]; desc = "Resolver" ; aux = @resolver.id.to_s
          @date1 = date_valid(@dateFrom) ; @date2 = date_valid(@dateTo)
          @numb = params[:num].to_i
            select_string = " sq.id squid, sq.updated_at, resolved_by, asked_question, status_state status  "
            jstring = " as sq join categories_submitted_questions as csq on csq.submitted_question_id=sq.id  "
            @pgt = " Questions Resolved by #{@resolver.first_name} #{@resolver.last_name} for '#{@cat.name}'"
            @faq = nil; @idtype='sqid'

            @questions = SubmittedQuestion.find_questions(@cat, desc, aux, nil, @date1, @date2,
               :all,  :select => select_string,  :joins => jstring, :order => order_clause("sq.updated_at", "desc"),
                     :page => params[:page], :per_page => AppConfig.configtable['items_per_page'])                                                          

       #    set_navigation_context('list', @questions, 'reports')
            @min = 124
           render  :template => "aae/reports/display_questions"
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
		
		if(params[:orderby] and ['name','total','handled','ratio','handled_average','hold_average'].include?(params[:orderby]))
			@orderby = params[:orderby]
		else 
			@orderby = 'name'
		end
		
		@userlist = User.find(:all, :select => "DISTINCT users.*", :joins => [:roles], :conditions => "role_id IN (3,4,5,6)", :order => "last_name,first_name #{@sortorder}")
  
		# this will get assigned, handled, and the ratio - assigned could be actual # of assignments minus 1 if the person is currently assigned something
	   handlingcounts = User.aae_handling_event_count({:group_by_id => true, :dateinterval => @dateinterval, :limit_to_handler_ids => @userlist.map(&:id),:submitted_question_filter => @filteroptions.merge({:notrejected => true})}) 
		handlingaverages = User.aae_handling_average({:group_by_id => true, :dateinterval => @dateinterval,:limit_to_handler_ids => @userlist.map(&:id),:submitted_question_filter => @filteroptions.merge({:notrejected => true})})  
		holdaverages = User.aae_hold_average({:group_by_id => true, :dateinterval => @dateinterval, :limit_to_handler_ids => @userlist.map(&:id),:submitted_question_filter => @filteroptions.merge({:notrejected => true})})  
   
		# let's merge this together
		@tmp_valuelist = []
		@userlist.each do |u|
			values = {}
			values[:user] = u
			values[:total] = handlingcounts[u.id].nil? ? 0 : handlingcounts[u.id][:total]
			values[:handled] = handlingcounts[u.id].nil? ? 0 : handlingcounts[u.id][:handled]
			values[:ratio] = handlingcounts[u.id].nil? ? 0 : handlingcounts[u.id][:ratio]
			values[:handled_average] = handlingaverages[u.id].nil? ? 0 : handlingaverages[u.id]
			values[:hold_average] = holdaverages[u.id].nil? ? 0 : holdaverages[u.id]
			@tmp_valuelist << values
		end
	
		# now sort it, if the orderby is name, don't bother, it's already sorted from the mysql query
		if(@orderby == 'name')
			@display_list = @tmp_valuelist
		else
			@display_list = ((@sortorder == 'asc') ? @tmp_valuelist.sort{|a,b| a[@orderby.to_sym] <=> b[@orderby.to_sym]} : @tmp_valuelist.sort{|a,b| b[@orderby.to_sym] <=> a[@orderby.to_sym]})
		end	
	end

     

    private 

    def setup_routers_and_wranglers
      @question_wrangler_ids = User.question_wranglers.map{|qw| qw.id}
      @auto_router_ids = User.auto_routers.map{|ar| ar.id}
    end   
      
end
