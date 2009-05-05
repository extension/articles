def to_state(zip)
  return case zip
      when  99501...99950 then 'AK'
      when  35004...36925 then 'AL'
      when  71601...72959 then 'AR'
      when  75502...75502 then 'AR'
      when  85001...86556 then 'AZ'
      when  90001...96162 then 'CA'
      when  80001...81658 then 'CO'
      when  6001...6389 then 'CT'
      when  6401...6928 then 'CT'
      when  20001...20039 then 'DC'
      when  20042...20599 then 'DC'
      when  20799...20799 then 'DC'
      when  19701...19980 then 'DE'
      when  32004...34997 then 'FL'
      when  30001...31999 then 'GA'
      when  39901...39901 then 'GA'
      when  96701...96898 then 'HI'
      when  50001...52809 then 'IA' 
      when  68119...68120 then 'IA'  
      when  83201...83876 then 'ID' 
      when  60001...62999 then 'IL' 
      when  46001...47997 then 'IN' 
      when  66002...67954 then 'KS' 
      when  40003...42788 then 'KY' 
      when  70001...71232 then 'LA' 
      when  71234...71497 then 'LA' 
      when  1001...2791 then 'MA' 
      when  5501...5544 then 'MA' 
      when  20331...20331 then 'MD' 
      when  20335...20797 then 'MD' 
      when  20812...21930 then 'MD' 
      when  3901...4992 then 'ME' 
      when  48001...49971 then 'MI' 
      when  55001...56763 then 'MN' 
      when  63001...65899 then 'MO' 
      when  38601...39776 then 'MS' 
      when  71233...71233 then 'MS' 
      when  59001...59937 then 'MT' 
      when  27006...28909 then 'NC' 
      when  58001...58856 then 'ND' 
      when  68001...68118 then 'NE' 
      when  68122...69367 then 'NE' 
      when  3031...3897 then 'NH' 
      when  7001...8989 then 'NJ' 
      when  87001...88441 then 'NM'
      when  88901...89883 then 'NV' 
      when  6390...6390 then 'NY' 
      when  10001...14975 then 'NY' 
      when  43001...45999 then 'OH' 
      when  73001...73199 then 'OK' 
      when  73401...74966 then 'OK' 
      when  97001...97920 then 'OR' 
      when  15001...19640 then 'PA' 
      when  2801...2940 then 'RI' 
      when  29001...29948 then 'SC' 
      when  57001...57799 then 'SD' 
      when  37010...38589 then 'TN' 
      when  73301...73301 then 'TX' 
      when  75001...75501 then 'TX' 
      when  75503...79999 then 'TX'
      when  88510...88589 then 'TX' 
      when  84001...84784 then 'UT' 
      when  20040...20041 then 'VA' 
      when  20040...20167 then 'VA' 
      when  20042...20042 then 'VA' 
      when  22001...24658 then 'VA'
      when  5001...5495 then 'VT'
      when  5601...5907 then 'VT'
      when  98001...99403 then 'WA'
      when  53001...54990 then 'WI'
      when  24701...26886 then 'WV'
      when  82001...83128 then 'WY'
      when  96799 then 'AS' #american somoa
      when  96941...96944 then 'FM' #micronesia
      when 800..851 then 'VI'
      when 600...1000 then 'PR'
      when 96950...96952 then 'MP' 'Nothern Mariana Islands'
      when  96960 then 'MH'
      when  96970 then 'MH'
      else 
        'OUTSIDEUS'
      end 
end

def flatten_hash_for_url(hash,pre_name = nil)
    return {} if !hash
    returnHash = {}
    hash.each{|hKey, hValue|
        if hValue.class == Hash || hValue.class == HashWithIndifferentAccess
          if pre_name
            returnHash.update( flatten_hash_for_url(hValue, pre_name.to_s+"["+hKey.to_s+"]") )
          else
            returnHash.update( flatten_hash_for_url(hValue, hKey.to_s) )
          end
        else
          if pre_name
            returnHash[pre_name.to_s+"["+hKey.to_s+"]"] = hValue.to_s
          else
            returnHash[hKey.to_s] = hValue.to_s
          end
        end
    }
    returnHash
end

class String
  def to_b
    return true if self.downcase == 'true'
    return false if self.downcase == 'false'
    nil
  end
end


def hash_string(string_to_hash , salt = 'default_salt')
    Digest::SHA1.hexdigest("--#{salt}--#{string_to_hash}--")
end
