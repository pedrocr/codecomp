require File.dirname(__FILE__)+"/../lib/all"
require File.dirname(__FILE__)+"/masscompare"

namespace :analysis do
  Dir.glob(File.expand_path("../analysis/",File.dirname(__FILE__))+"/*.rb").each{|file| require file}
end
