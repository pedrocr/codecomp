require File.dirname(__FILE__)+"/tasks/all.rb"

DISTS = ["jaunty","karmic","lucid","maverick","natty"]
DISTPAIRS = DISTS[0..-2].zip(DISTS[1..-1])
DATADIR = File.expand_path("data/", File.dirname(__FILE__))

desc "Compare all distributions"
task :compare_all_dists do
  DISTPAIRS.each do |d1,d2| 
    mass_compare(d1,d2)
  end
end

desc "Run everything"
task :default => [:compare_all_dists]
