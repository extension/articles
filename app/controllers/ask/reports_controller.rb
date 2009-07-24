class Ask::ReportsController < ApplicationController
  
   layout  'aae_reports_home'  
   

     def index
       @locs = Location.find(:all, :order => "entrytype, name")
     end


    ##Activity Reports
    def activity
      # (@date1,@date2, @dateFrom,@dateTo)= valid_date()
      # (@date1,@date2,@dateFrom,@dateTo)= errchk(@date1,@date2,@dateFrom,@dateTo)
       @oldest_date = SubmittedQuestion.find_oldest_date
       @date1 = nil; @date2 = nil; @dateFrom = nil; @dateTo = nil; 
       @new= 0; @answ = 0; @resolved=0; @rej = 0; @noexprtse=0
       @rept = Aaereport.new(:name => "Activity")
       @repaction = "activity"
       @cats = Category.find(:all, :order => 'name')
    end

     def state_univ_activity
      @typelist = [];  @new={}; @reslvd={}; @answ={}; @rej={}; @noexp={} ; openquestions={}
        @type = params[:type]; @oldest_date = SubmittedQuestion.find_oldest_date
       #   (@date1, @date2, @dateFrom, @dateTo)=parmcheck()
        if (@type=="State")
          @typelist  = Location.find(:all, :order => "entrytype, name")
        else
          @typelist = Institution.find(:all, :order => 'name')
        end
         @date1 = nil; @date2 = nil; @dateFrom = nil; @dateTo = nil; typel= @type.downcase
         @rept = Aaereport.new(:name => "ActivityGroup")
         
         if @type=="State"
          openquestions = (@rept.NewQuestion({:g => typel},[]))[0] 
         end
          resolved = (@rept.ResolvedQuestion({:g => typel},[]))[0]
          answered = (@rept.ResolvedQuestion({:g => typel, :status_state => SubmittedQuestion::STATUS_RESOLVED},[]))[0]
          rejected = (@rept.ResolvedQuestion({:g => typel, :status_state => SubmittedQuestion::STATUS_REJECTED},[]))[0]
          noexp = (@rept.ResolvedQuestion({:g => typel, :status_state => SubmittedQuestion::STATUS_NO_ANSWER},[]))[0]
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
       render :template=>'ask/reports/common_sorted_lists'
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

    def activity_by_institution
      params[:type] = "Institution"
      common_display
    end

      def transform_typelist(typl)
         nar = []; typl.map { |nm| nar << [nm.name] } 
         nar
       end  

       def show_active_cats
         @filteredparams = FilterParams.new(params)  #...can this be useful here?
           @typename = params[:Category]
            cat = Category.find_by_name(params[:Category]) 
            @type = "Category" ; @typel="category"; @typet="Tag"
            @date1 = nil; @date2 = nil; @dateFrom = nil; @dateTo = nil; 
         #   @oldest_date = SubmittedQuestion.find_oldest_date
      #   (@date1, @date2, @dateFrom, @dateTo)=parmcheck()
            @typelist = [cat]
            if !cat.nil?
                #tagname = Tag.normalize_tag(cat.name)
                @rept = Aaereport.new(:name => "ActivityCategory")
                render :template=>'ask/reports/common_lists'
            else
                redirect_to :controller => 'ask/reports', :action => 'sel_active_cats' 
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
                self.send((report+"_by_#{typ.downcase}").intern)
            else
              case typ    #remake the variable lists 
                when 'Institution', 'State'
                  self.send(("state_univ_"+report).intern)
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
                 render :template=>'ask/reports/common_sorted_lists'
              when 'response_times'
                 render :template => 'ask/reports/common_resptimes_lists'
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
            @cat = Category.find_by_name(params[:Category])
            @olink = params[:olink]; @comments=nil; @edits=params[:descriptor]; @idtype='sqid'
            @date1 = nil; @date2 = nil; @dateFrom = nil; @dateTo = nil; aux = nil ; @catname = params[:Category]
          #  @dateFrom = params[:from] ;  @dateTo=params[:to]
         #   @date1 = date_valid(@dateFrom) ; @date2 = date_valid(@dateTo)
            desc = params[:descriptor]; @numb = params[:num].to_i
             if (@edits.length > 8)
               if (@edits[0..7]=="Resolved")
                 aux = @edits[8].chr
                 @edits = "Resolved"
               end
             end
              select_string = " sq.id squid, sq.updated_at updated_at, resolved_by, asked_question, sq.question_updated_at, sq.status status"
              jstring = " as sq join categories_submitted_questions as csq on csq.submitted_question_id=sq.id "
              (desc=="New") ? @pgt = " Newly Submitted Questions in '#{@cat.name}'  " : @pgt = " Questions Resolved from Ask an Expert for '#{@cat.name}'"

              @questions = SubmittedQuestion.find_questions(@cat, @edits, aux, @date1, @date2,
                 :all,  :select => select_string,  :joins => jstring, :order => order_clause("sq.updated_at", "desc"),
                       :page => params[:page], :per_page => AppConfig.configtable['items_per_page'])                                                
              @min = 124
             render  :template => "ask/reports/display_questions"
        end
        
        ######   User Report of Ask an Expert Activity #####
        
        def user_report

        end
         
         def locate
            if params[:u].nil?
              flash[:failure] = "No Username entered."
              # needs to be changed to go "back"
              redirect_to :controller => 'main', :action => 'welcome'
              return
            elsif params[:u].strip == ''
              flash[:failure] = "No Username entered."
              redirect_to :controller => 'main', :action => 'welcome'
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
                flash[:failure] = "Username unrecognized."   
                redirect_to :controller => 'reports', :action => 'user_report'
              end   
            end
          end
          
        
        def user
     #     if (params[:from] && params[:to])
    #        @dateFrom = params[:from] ;  @dateTo=params[:to]
    #        @date1 = date_valid(@dateFrom) ; @date2 = date_valid(@dateTo)
    #      else
    #        (@date1,@date2,@dateFrom,@dateTo)=valid_date()
    #        (@date1,@date2,@dateFrom,@dateTo)= errchk(@date1,@date2,@dateFrom,@dateTo)
    #      end
          @date1 = nil; @date2 = nil
          @oldest_date = SubmittedQuestion.find_oldest_date
          @user = User.find_by_id(params[:id])
       
          @uresolved = @user.resolved_questions.date_subs(@date1, @date2).count(:conditions => "status_state in (#{SubmittedQuestion::STATUS_RESOLVED}, #{SubmittedQuestion::STATUS_REJECTED}, #{SubmittedQuestion::STATUS_NO_ANSWER})")
          @avgstdresults = @user.get_avg_resp_time(@date1, @date2)
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
           desc = params[:descriptor]; @numb = params[:num].to_i

             select_string = " sq.current_contributing_question question_id, sq.user_id, sq.id squid,  resolved_by, " +
                " sq.status status, sq.created_at, sq.updated_at updated_at, asked_question " 
            
             @pgt = "Questions #{@user.first_name} #{@user.last_name} #{desc} "
             @faq = nil; @idtype='sqid'
        
        
             @questions = SubmittedQuestion.find_questions(@user, desc,nil, @date1, @date2,
                                                            :all,
                                                            :select => select_string,
                                                            :joins => " as sq ",
                                                            :order => order_clause("sq.updated_at", "desc"),
                                                            :page => params[:page],
                                                            :per_page => AppConfig.configtable['items_per_page'])
    

         #   set_navigation_context('list', @questions, 'reports')

        end
        
        ####   end of User Report for Ask an Expert Activity #####
         
         ####  Date handling ###
         def valid_date()
           dateFrom = params["dateFrom"]["to_s"] if (params["dateFrom"] && params["dateFrom"]["to_s"]) 
           date1 = date_valid(dateFrom)
           dateTo = params["dateTo"]["to_s"] if (params["dateTo"] && params["dateTo"]["to_s"]) 
           date2 = date_valid(dateTo)
           [date1, date2, dateFrom, dateTo]
         end

          def valid_compare_date()
            dateFrom = params["datecFrom"]["to_s"] if (params["datecFrom"] && params["datecFrom"]["to_s"]) 
            date1 = date_valid(dateFrom)
            dateTo = params["datecTo"]["to_s"] if (params["datecTo"] && params["datecTo"]["to_s"]) 
            date2 = date_valid(dateTo)
            [date1, date2, dateFrom, dateTo]
          end
          
          def valid_compare_date_calselct()
            dateFrom = params["datecFrom"] if (params["datecFrom"] ) 
            if dateFrom
              dateFrom = dateFrom[6..9] + "-" + dateFrom[0..1] + "-" + dateFrom[3..4]
            end
            date1 = date_valid(dateFrom)
            dateTo = params["datecTo"] if (params["datecTo"] )
            if dateTo
              dateTo = dateTo[6..9] + "-" + dateTo[0..1] + "-" + dateTo[3..4]
            end
            date2 = date_valid(dateTo)
            [date1, date2, dateFrom, dateTo]
          end

          def date_valid(yyyymmdd)
              #yyyymmdd = yyyy-mm-dd
              return nil if !yyyymmdd || yyyymmdd=="" 
              return Time.parse(yyyymmdd)
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

          def parmcheck
              if params[:bysort] !="y"
                if params[:FromDate]
                  dateFrom = params[:FromDate]
                else
                  dateFrom = params["dateFrom"]["to_s"] if (params["dateFrom"] && params["dateFrom"]["to_s"])
                end
                date1 = date_valid(dateFrom)
                if params[:ToDate]
                  dateTo=params[:ToDate]
                else
                  dateTo = params["dateTo"]["to_s"] if (params["dateTo"] && params["dateTo"]["to_s"])
                end
                date2 = date_valid(dateTo)
              else
                dateFrom = params[:from]
                dateTo=params[:to]
                date1 = date_valid(dateFrom)
                date2 = date_valid(dateTo)
              end

              (date1, date2, dateFrom, dateTo)= errchk(date1,date2,dateFrom,dateTo)
              [date1, date2, dateFrom, dateTo]
          end    

          def parmccheck
            if params[:bysort] !="y"
              if params[:FromcDate]
                dateFrom = params[:FromcDate]
              else
                dateFrom = params["datecFrom"]["to_s"] if (params["datecFrom"] && params["datecFrom"]["to_s"])
              end
              date1 = date_valid(dateFrom)
              if params[:TocDate]
                dateTo=params[:TocDate]
              else
                dateTo = params["datecTo"]["to_s"] if (params["datecTo"] && params["datecTo"]["to_s"])
              end
              date2 = date_valid(dateTo)
            else
              dateFrom = params[:fromc]
              dateTo=params[:toc]
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
                 :group => "users.location_id", :order => "entrytype, name")
        end

        def state_answerers
         @filteredparams = FilterParams.new(params) 
         @filteredoptions = @filteredparams.findoptions 
          if params[:id]
            @catname = Category.find_by_id(params[:id]).name
            catid = params[:id]
          else
            if params[:category]
              @catname=params[:category]
              catid = Category.find_by_name(@catname).id
            end
          end 
          if (@catname  && @catname != "")
            @locs = ExpertiseLocation.find(:all, :order => 'entrytype, name')
           # @loccnt = ExpertiseLocation.count_answerers_for_states_in_category(@catname)
            @loccnt = ExpertiseLocation.expert_loc_userfilter_count(@filteredoptions)
            @userlist = consolidate(User.get_answerers_in_category(catid))
            @capcatname = @catname[0].chr.to_s.upcase + @catname[1..(@catname.length - 1)]
            @lsize = @locs.size
            @usize = @userlist.size
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
             @userlist = consolidate(ExpertiseLocation.get_users_in_state(params[:location]))
             @usize = @userlist.size ; @locid = params[:location]
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
      #       @cntycnt = ExpertiseCounty.count(:all,:select => "ecu.user_id", :joins => " join expertise_counties_users as ecu on ecu.county_id=expertise_counties.id " + 
      #          "join users on ecu.user_id=users.id join expertise_areas as ea on ecu.user_id=ea.user_id join categories as c on ea.category_id=c.id",
      #          :conditions =>  ["expertise_counties.location_id=? and c.parent_id is null", ExpertiseLocation.find_by_name(@statename).id],
      #          :group => "expertise_counties.name", :distinct => "true")
      #          
      #      #  userlist = ExpertiseLocation.find_by_sql(["Select distinct users.id, users.first_name, users.last_name, users.login, roles.name, roles.id as rid from expertise_locations join expertise_locations_users as lu on lu.location_id=expertise_locations.id " +
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
          #   @ctycnt = Category.count_users_for_rootcats_in_county(@county, @statename)
             @ctycnt = Category.catuserfilter_count(@filteredoptions)
             @userlist= consolidate(ExpertiseCounty.get_users_for_cats_in_county(params[:county]))
             @usize = @userlist.size
          end
        end

        def category_county_users
          if params[:State]
            @statename = params[:State]
            @locid = ExpertiseLocation.find_by_name(@statename)
          end
          if params[:County]
            @county = params[:County]
          end
          if params[:Category]
            @catname = params[:Category]
          end
          if (@statename && @county && @catname && @statename !="" && @county != "" && @catname != "")
            @capcatname = @catname[0].chr.to_s.upcase + @catname[1..(@catname.length - 1)]
            countyid = ExpertiseCounty.find(:first, :conditions => ["expertise_location_id=#{ExpertiseLocation.find_by_name(@statename).id} and name=?", @county]).id
            @userlist = consolidate(ExpertiseCounty.get_users_for_counties(countyid, @statename, @catname))
            @usize = @userlist.size
          end
        end

        def consolidate(uarray)
          # if more than one of the same userid appears with different roles, consolidate 
           newarr = Array.new
           len = uarray.length
           i = 0
           while i < len do
             if ((i == 0) || (uarray[i].id != uarray[i-1].id))
               wrangsymb = " "; autorsymb = " "
               if uarray[i].rid == "3"
                 wrangsymb = "+"
               end  
               if uarray[i].rid == "4"
                  autorsymb = "*"
                end 
               newarr << [ uarray[i].id, uarray[i].first_name, uarray[i].last_name, uarray[i].login, uarray[i].name, uarray[i].rid , autorsymb, wrangsymb]  
             else
               if uarray[i].rid == "3"
                 newarr[newarr.length() - 1][7] = "+"     
               else
                 if uarray[i].rid == "4"
                   newarr[newarr.length() -1][6]= "*"
                 end
               end
             end
             i = i + 1
           end
           newarr
        end

        def county_answerers
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
          if params[:dir]
            @dir = params[:dir]
          end
          if (@statename && @statename != "")
            @cnties = ExpertiseCounty.find(:all,  :conditions => "expertise_location_id = #{Location.find_by_name(@statename).id}", :order => 'countycode, name').collect { |nm| [nm.name, nm.id]}
            @cntycnt = ExpertiseCounty.count_answerers_for_county_and_category(@catname, @statename)
            @capcatname = @catname[0].chr.to_s.upcase + @catname[1..(@catname.length - 1)]
            @userlist = consolidate(ExpertiseCounty.get_users_for_counties(nil, @statename, @catname))
            @csize = @cnties.size
            @usize = @userlist.size
          else
            redirect_to :action => 'state_answerers', :Category => @catname
          end  
        end

        def answerers_lists
          @statename = params[:State]
          @catname = params[:Category]
          @county = params[:County]
          if params[:dir]
            @dir=params[:dir]
          end
          if (!@catname || @catname=="")
            redirect_to :action => 'answerers'
          end
          if (!@statename || @statename =="") 
            redirect_to :action => 'state_answerers', :Category => @catname
          end
          if (@county)
            countyid = ExpertiseCounty.find(:first, :conditions => ["expertise_location_id=#{ExpertiseLocation.find_by_name(@statename).id} and name=?", @county]).id
            @capcatname = @catname[0].chr.to_s.upcase + @catname[1..(@catname.length - 1)]
          # form array of users for selected county
            @userlist = consolidate(ExpertiseCounty.get_users_for_counties(countyid, @statename, @catname))
            @usize = @userlist.size
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
         (@date1,@date2,@dateFrom,@dateTo)=valid_date()
         (@date1,@date2,@dateFrom,@dateTo)= errchk(@date1,@date2,@dateFrom,@dateTo)
       end
       @typename = params[:State]; 
       if (@typename && @typename != "") 
         @typeobj = Location.find_by_name(params[:State]) 
         @type = "State" ; @typel="state" ;  @oldest_date = SubmittedQuestion.find_oldest_date
         locabbr=@typeobj.abbreviation; locid = @typeobj.id
     
         if !@typeobj.nil?  
      
           @reguser = User.date_users(@date1, @date2).count(:conditions => "location_id=#{locid}")
        
           @asgn = SubmittedQuestion.date_subs(@date1, @date2).count(:conditions =>  " status_state=#{SubmittedQuestion::STATUS_SUBMITTED} and location_id=#{@typeobj.id}")
           (@answp, @answpa, @answpr, @answpn)= SubmittedQuestion.get_answered_question_by_state_persp("pertaining",@typeobj, @date1, @date2)
           (@answm, @answma, @answmr, @answmn)= SubmittedQuestion.get_answered_question_by_state_persp("member", @typeobj, @date1, @date2)
       
           @repaction = "show_all_by_state"      
           render :template=>'ask/reports/state'

         else
           redirect_to :controller => 'ask/reports', :action => 'state_report'
         end
       else
         redirect_to :controller => 'ask/reports', :action => 'index'
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
         @dateFrom = params[:from] ;  @dateTo=params[:to] ; @oldest_date = SubmittedQuestion.find_oldest_date
         @date1 = date_valid(@dateFrom) ; @date2 = date_valid(@dateTo)
         
         @limit_string = "Only up to 100 are shown."
        
         
             (@edits[0..7]== "Resolved") ?  jrestring = " join users on sq.resolved_by=users.id " :  jrestring=""
             select_string = "sq.user_id, sq.id squid, resolved_by, sq.location_id, current_contributing_question question_id,  " +
                " sq.status status, sq.created_at, sq.updated_at updated_at, asked_question " 
            
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
          render  :template => "ask/reports/display_questions"
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
         redirect_to :controller => 'ask/reports', :action => 'index'
       end
     end


     def county
       if (params[:from] && params[:to])
         @dateFrom = params[:from] ;  @dateTo=params[:to]
         @date1 = date_valid(@dateFrom) ; @date2 = date_valid(@dateTo)
       else
         (@date1,@date2,@dateFrom,@dateTo)=valid_date()
         (@date1,@date2,@dateFrom,@dateTo)= errchk(@date1,@date2,@dateFrom,@dateTo)
       end
       @county = params[:County]; @typename = @county
       @statename=params[:State]
       if (@county && @statename && @statename!="")
         loc=Location.find_by_name(@statename) 
         locabbr = loc.abbreviation
        
         @typeobj = County.find(:first, :conditions => ["location_id= ? and name= ?", loc.id, @county])
         @type="County"; @typel="county" ;   @oldest_date = SubmittedQuestion.find_oldest_date
         if !@typeobj.nil? 
       
           @reguser = User.date_users(@date1, @date2).count(:conditions => "county_id = #{@typeobj.id}")
         
          @asgn = SubmittedQuestion.date_subs(@date1, @date2).count(:conditions =>  " status_state=#{SubmittedQuestion::STATUS_SUBMITTED} and county_id=#{@typeobj.id}")
          (@answp, @answpa, @answpr, @answpn)= SubmittedQuestion.get_answered_question_by_county_persp("pertaining",@typeobj, @date1, @date2)
          (@answm, @answma, @answmr, @answmn)= SubmittedQuestion.get_answered_question_by_county_persp("member",@typeobj, @date1, @date2)   
          
           @repaction = 'county'
           render :template => 'ask/reports/state'
        else
          redirect_to :controller => 'ask/reports', :action => 'county_select', :State => @statename
        end
      else
         redirect_to :controller => 'ask/reports', :action => 'index'
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
                (@date1, @date2, @dateFrom, @dateTo) = parmcheck()
              else
                (@date1,@date2,@dateFrom,@dateTo)=valid_date()
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
               (@datec1, @datec2, @datecFrom, @datecTo) = parmccheck()
            else
              (@datec1,@datec2,@datecFrom,@datecTo)=valid_compare_date()  #not valid_compare_date_selct() until that's got more javascript
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
       @oldest_date = SubmittedQuestion.find_oldest_date
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
       noopen = SubmittedQuestion.named_date_resp(date1, date2).count(:joins => [:categories], :conditions => " status = 'submitted' and external_app_id #{extstr} ", :group => 'category_id')
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
        render :template=>'ask/reports/common_resptimes_lists'
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
              :conditions =>  " status = 'submitted' and external_app_id #{extstr} ", :group => "users.location_id")
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
          render :template=>'ask/reports/common_resptimes_lists'
       end
       
       ## end of Response Times Report   
  
    #### Start of Responders by Category Report ####
       def resolved_responders_by_category
         @noresponders = Hash.new; @responderslist = Hash.new
         @typelist = Category.find(:all, :conditions => "parent_id is null", :order => 'name')
          @typelist.each do |cat|
            userarray = SubmittedQuestion.resolved_submitted_questions_by_category_users(cat.id)
            @noresponders[cat.name]= userarray[1]
            @responderslist[cat.name]=userarray[2]
          end
       end

       def display_discrete_responded
          @cat = Category.find_by_name(params[:cat]); @resolver=User.find_by_id(params[:id])
          @olink = params[:olink]; @comments=nil; @edits="Resolved"; @idtype='id'
          @dateFrom = params[:from] ;  @dateTo=params[:to]; desc = "Resolver" ; aux = @resolver.id.to_s
          @date1 = date_valid(@dateFrom) ; @date2 = date_valid(@dateTo)
          @numb = params[:num].to_i
            select_string = " sq.id squid, sq.updated_at, resolved_by, asked_question, status status  "
            jstring = " as sq join categories_submitted_questions as csq on csq.submitted_question_id=sq.id  "
            @pgt = " Questions Resolved by #{@resolver.first_name} #{@resolver.last_name} for '#{@cat.name}'"
            @faq = nil; @idtype='sqid'

            @questions = SubmittedQuestion.find_questions(@cat, desc, aux,  @date1, @date2,
               :all,  :select => select_string,  :joins => jstring, :order => order_clause("sq.updated_at", "desc"),
                     :page => params[:page], :per_page => AppConfig.configtable['items_per_page'])                                                          

       #    set_navigation_context('list', @questions, 'reports')
            @min = 124
           render  :template => "ask/reports/display_questions"
       end
   ####   End of Responders by Category Report ###
  
end
