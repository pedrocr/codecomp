DISTS = ["jaunty","karmic","lucid","maverick","natty"]
DISTPAIRS = DISTS[0..-2].zip(DISTS[1..-1])
DATADIR = File.expand_path("data/", File.dirname(__FILE__))
GENDIR = File.expand_path("generated/", File.dirname(__FILE__))
TASKSDIR = File.expand_path("tasks/", File.dirname(__FILE__))
ANALYSISDIR = File.expand_path("analysis/", File.dirname(__FILE__))
TMPDIR = File.expand_path("tmpdir/", File.dirname(__FILE__))
FileUtils.mkdir_p TMPDIR

require "lib/all"
require "analysis/common"

Dir.glob(TASKSDIR+"/*.rb").each{|file| require file}
namespace :analysis do |n|
  Dir.glob(ANALYSISDIR+"/*.rb").each do |file|
    RTask.new(file) if File.basename(file) != "common.rb"
  end
  task :all => n.tasks.map{|t| t.name}
end

desc "Run all analysis"
task :analysis => ["analysis:all"]

desc "Run everything"
task :default => ["analysis"]
