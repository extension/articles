class Aaereport < ActiveRecord::Base
  
  
    attr_reader :idents
        
    def initialize(inhash={})
      @idents = inhash
    end
  
  
  #Activity Submitted Questions
  def NewQuestion(p, results)
    p.merge!(@idents[:filters]) if @idents[:filters]
    cond = buildcond(p, this_method, ["status_state=#{SubmittedQuestion::STATUS_SUBMITTED}"])
    jstr = buildjoin(p, this_method)
    grp = buildgroup(p, this_method)
    results << SubmittedQuestion.date_subs(p[:date1], p[:date2]).count(:joins => jstr, :conditions => cond, :group => grp)
  end
  
  #Activity Answered Questions
  def ResolvedQuestion(p, results)
    p.merge!(@idents[:filters]) if @idents[:filters]
    jstr = buildjoin(p, this_method)
    cond = buildcond(p, this_method, ["resolved_by >= 1"])
    grp = buildgroup(p, this_method)
    results << SubmittedQuestion.date_subs(p[:date1], p[:date2]).count(:joins => jstr, :conditions => cond, :group => grp)
  end
  
  
   def buildjoin(p, caller_method)
      if  (caller_method=="ResolvedQuestion")
         if  @idents[:name]=="ActivityGroup"
           return  [:resolved_by]
         elsif @idents[:name]=="ActivityCategory"
            if  p[:location]
              return "join categories_submitted_questions on categories_submitted_questions.submitted_question_id=submitted_questions.id " +
                     " join categories on categories.id=categories_submitted_questions.category_id join locations on submitted_questions.location_id=locations.id "
            else
              return [:categories]
            end
         end
      end
      if (caller_method=="NewQuestion" )
         if p[:catid]  && p[:location]
            return "join categories_submitted_questions on categories_submitted_questions.submitted_question_id=submitted_questions.id " +
                   " join categories on categories.id=categories_submitted_questions.category_id join locations on submitted_questions.location_id=locations.id "
          elsif p[:catid]
            return [:categories]
          end
        case p[:g]
        when "state"
          return  [:location]
     #   when "institution"
     #        return  "join users on submitted_by=users.id"  ...not used anymore
        end
      end
   end
   
   def buildcond(p, caller_method, cond)
     cond = cond || []
  #   if p[:cats] 
  #     cond << "tags.name IN (#{p[:cats]})"
  #   end
     if p[:catid]
       cond << "category_id=#{p[:catid]}"
     end
     if p[:location]
       if (p[:location].class != Fixnum)
        cond << " locations.id=#{p[:location].id}"
       else
        cond << " locations.id=#{p[:location]}"
       end
     end
     if p[:status_state]
       cond << " status_state=#{p[:status_state]}"
     end
     if p[:g]=="institution"
       cond << " users.vouched = 1 and users.retired = 0"
     end
     if cond.empty?; return nil
     else
       return cond.join(" and ") 
     end
   end
   
    def buildgroup(p, caller_method)
      if ( @idents[:name]=="ActivityGroup")
       case p[:g]
        when "state"
          return "submitted_questions.location_id"
        when "institution"
            return "institution_id"
       end
      end
    end
   

end
