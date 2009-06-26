class Ask::ReportsController < ApplicationController
  
   layout  'aae_reports_home'  
     skip_before_filter :check_authorization
   

     def index
       @locs = Location.find(:all, :order => "entrytype, name")
     end

    def activity
       @oldest_date = SubmittedQuestion.find_oldest_date
       @date1 = nil; @date2 = nil; @dateFrom = nil; @dateTo = nil; 
       @new= 0; @answ = 0; @resolved=0; @rej = 0; @noexprtse=0
       @rept = Aaereport.new(:name => "Activity")
       @repaction = "activity"
       @cats = Category.find(:all, :order => 'name')
    end

     def state_univ_activity
      @typelist = [];  @new={}; @reslvd={}; @answ={}; @rej={}; @noexp={}
        @type = params[:type]; @oldest_date = SubmittedQuestion.find_oldest_date
        if (@type=="State")
          @typelist  = Location.find(:all, :order => "entrytype, name")
        else
          @typelist = Institution.find(:all, :order => 'name')
        end
         @date1 = nil; @date2 = nil; @dateFrom = nil; @dateTo = nil; typel= @type.downcase
         @rept = Aaereport.new(:name => "ActivityGroup")
         
          openquestions = (@rept.NewQuestion({:g => typel},[]))[0] 
          resolved = (@rept.ResolvedQuestion({:g => typel},[]))[0]
          answered = (@rept.ResolvedQuestion({:g => typel, :status_state => SubmittedQuestion::STATUS_RESOLVED},[]))[0]
          rejected = (@rept.ResolvedQuestion({:g => typel, :status_state => SubmittedQuestion::STATUS_REJECTED},[]))[0]
          noexp = (@rept.ResolvedQuestion({:g => typel, :status_state => SubmittedQuestion::STATUS_NO_ANSWER},[]))[0]
            stuv = nil
             @typelist.each do |st|
               if (@type=="State"); stuv= st.id; else; stuv=st.id.to_s; end;
                @new[st.name]= openquestions[stuv]
                ActiveRecord::Base::logger.debug "stuv=" + stuv.to_s + " st.name= " + st.name + ((resolved[stuv]) ? resolved[stuv].to_s : "nil")
                @reslvd[st.name] = resolved[stuv]
                @answ[st.name] = answered[stuv]
                @rej[st.name] = rejected[stuv]
                @noexp[st.name] = noexp[stuv]
              end
          
          if (@type=="State")
              @repaction = "activity_by_state"     
          else
              @repaction = "activity_by_institution"
          end
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
      params[:type] = "University"
      common_display
    end

      def transform_typelist(typl)
         nar = []; typl.map { |nm| nar << [nm.name] } 
         nar
       end  

       def show_active_cats
           @typename = params[:Category]
            cat = Category.find_by_name(params[:Category]) 
            @type = "Category" ; @typel="category"; @typet="Tag"
        #    (@date1, @date2, @dateFrom, @dateTo)=parmcheck()
            @date1 = nil; @date2 = nil; @dateFrom = nil; @dateTo = nil; 
         #   @oldest_date = SubmittedQuestion.find_oldest_date
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
            if fld == 'State'
               case typ      #if this is the 'State' fld then this is the anchor, describing by what this is organized
                             #remake the variable lists starting over from the beginning
               when 'University'
                  self.send((report+"_by_institution").intern)
               else
                 self.send((report+"_by_#{typ.downcase}").intern)
               end

            else
              case typ    #remake the variable lists 
                when 'University', 'State'
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
            #  when 'response_times'
            #     render :template => 'reports/common_resptimes_lists'
              end
           end
       end
  
end
