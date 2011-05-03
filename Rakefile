require File.dirname(__FILE__)+"/tasks/all.rb"

DISTS = ["jaunty","karmic","lucid","maverick"]

desc "Compare all distributions"
task :compare_all_dists do
  DISTS[0..-2].zip(DISTS[1..-1]).each do |d1,d2| 
    mass_compare(d1,d2)
  end
end

desc "Run everything"
task :default => [:compare_all_dists]
