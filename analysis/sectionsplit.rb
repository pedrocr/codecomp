require "faster_csv"

desc "plot sections by code churn"
task :sectionsplit => [:compare_all_dists] do
  churns = {}
  n = 0

  CompResult.each(:with_dists => :true) do |cmp, dist1, dist2|
    if cmp.from_section && cmp.to_section and cmp.from_section != cmp.to_section
      Util.warn "#{cmp.from} has section #{cmp.from_section} and #{cmp.to} has section #{cmp.to_section}"
    end
    section = cmp.to_section||cmp.from_section
    churns[section] ||= {}
    churns[section]["#{dist1}_#{dist2}"] ||= 0
    churns[section]["#{dist1}_#{dist2}"] += (cmp.insertions.to_i+cmp.deletions.to_i)
    n += 1
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
