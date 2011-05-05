require "faster_csv"

class CompResult
  def initialize(names,values)
    names.zip(values).each do |name, value| 
      self.instance_eval "def #{name}; \"#{value}\"; end"
    end
  end
  
  def self.each(dist1,dist2)
    names = nil
    FasterCSV.foreach(DATADIR+"/#{dist1}_#{dist2}_comparisons") do |row|
      if !names
        names = row
      else
        yield CompResult.new(names,row)
      end
    end          
  end
end

desc "plot sections by code churn"
task :sectionsplit do
  DISTPAIRS.each do |dist1, dist2|
    n = 0
    CompResult.each(dist1,dist2) do |cmp|
      n+=1
    end
    puts "#{n} comparisons between #{dist1} and #{dist2}"
  end
end
