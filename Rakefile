DISTS = ["jaunty","karmic","lucid","maverick","natty"]
DISTPAIRS = DISTS[0..-2].zip(DISTS[1..-1])
DATADIR = "data/"
GENDIR = "generated/"
TASKSDIR = "tasks/"
ANALYSISDIR = "analysis/"
TMPDIR = "tmpdir/"
FileUtils.mkdir_p [TMPDIR,GENDIR]

require "lib/all"
require "analysis/common"

Dir.glob(TASKSDIR+"/*.rb").each{|file| require file}
namespace :analysis do |n|
  Dir.glob(ANALYSISDIR+"*.rb").each do |file|
    RTask.new(file) if File.basename(file) != "common.rb"
  end
  task :all => n.tasks.map{|t| t.name}
end

desc "Run all analysis"
task :analysis => ["analysis:all"]

desc "Run everything"
task :default => ["analysis"]
