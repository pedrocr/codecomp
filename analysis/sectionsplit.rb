require "faster_csv"

class CompResult
  # c = CompResult.new(["a"],[1])
  # c.a #=> 1
  #
  # This is a wrapper to make the code look pretty when iterating the csv files
  # it probably has atrocious performance as it creates a new object per row
  # and does an instance_eval per cell
  def initialize(names,values)
    names.zip(values).each do |name, value| 
      self.instance_eval "def #{name}; #{value.inspect}; end"
    end
  end
  
  def self.each(dist1,dist2)
    names = nil
    FasterCSV.foreach(GENDIR+"/#{dist1}_#{dist2}_comparisons") do |row|
      if !names
        names = row
      else
        yield CompResult.new(names,row)
      end
    end          
  end
end

desc "plot sections by code churn"
task :sectionsplit => [:compare_all_dists] do
  churns = {}
  n = 0
  DISTPAIRS.each do |dist1, dist2|
    CompResult.each(dist1,dist2) do |cmp|
      if cmp.from_section && cmp.to_section and cmp.from_section != cmp.to_section
        Util.warn "#{cmp.from} has section #{cmp.from_section} and #{cmp.to} has section #{cmp.to_section}"
      end
      section = cmp.to_section||cmp.from_section
      churns[section] ||= {}
      churns[section]["#{dist1}_#{dist2}"] ||= 0
      churns[section]["#{dist1}_#{dist2}"] += (cmp.insertions.to_i+cmp.deletions.to_i)
      n += 1
    end
  end
  churnfile = GENDIR+"/sectionchurn"
  puts "Writing #{File.expand_path(churnfile)}"
  File.open(churnfile, "w") do |f|
    f.puts((["section"]+DISTPAIRS.map{|d1,d2| "#{d1}_#{d2}"}).join(","))
    churns.each do |section, cs|
      f.puts(([section]+DISTPAIRS.map{|d1,d2| cs["#{d1}_#{d2}"]||0}).join(","))
    end
  end
  puts "Processed #{n} comparisons"
end
