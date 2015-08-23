# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

#############################
# Statistics Module for Ruby
# (C) Derrick Pallas
#
# Authors: Derrick Pallas
# Website: http://derrick.pallas.us/ruby-stats/
# License: Academic Free License 3.0
# Version: 2007-10-01b
#

class Numeric
  def square ; self * self ; end
end

class Array
  # sum already defined for enumerable by rails
  #def sum ; self.inject(0){|a,x|x+a} ; end
  def mean ; self.sum.to_f/self.size ; end
  def median
    case self.size % 2
      when 0 then self.sort[self.size/2-1,2].mean
      when 1 then self.sort[self.size/2].to_f
    end if self.size > 0
  end
  def histogram ; self.sort.inject({}){|a,x|a[x]=a[x].to_i+1;a} ; end
  def mode
    map = self.histogram
    max = map.values.max
    map.keys.select{|x|map[x]==max}
  end
  def squares ; self.inject(0){|a,x|x.square+a} ; end
  def variance ; self.squares.to_f/self.size - self.mean.square; end
  def deviation ; Math::sqrt( self.variance ) ; end
  def permute ; self.dup.permute! ; end
  def permute!
    (1...self.size).each do |i| ; j=rand(i+1)
      self[i],self[j] = self[j],self[i] if i!=j
    end;self
  end

  # nist calculation: http://www.itl.nist.gov/div898/handbook/prc/section2/prc252.htm
  def nist_percentile(percentile)
    sorted = self.dup.sort!
    length = sorted.length
    n = (length+1)
    p_sub_n = (percentile/100) * n
    k = p_sub_n.floor
    if(k == 0)
      sorted[0]
    elsif(k == length)
      sorted[k-1]
    else
      d = (p_sub_n) - k
      (sorted[k-1] + d * (sorted[k] - sorted[k-1]))
    end
  end
end
