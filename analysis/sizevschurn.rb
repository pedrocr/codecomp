desc "predict code churn based on size"
task :sizevschurn => [:compare_all_dists] do
  File.open(GENDIR+"/sizevschurn", "w") do |f|
    f.puts "CHURN SIZE LN_SIZE"
    CompResult.each do |cmp|
      if cmp.from != "nil" and cmp.to != "nil"
        size = (cmp.from_loc.to_i+cmp.to_loc.to_i)/2
        churn = (cmp.insertions.to_i+cmp.deletions.to_i).to_f/size.to_f*100
        if size != 0 and churn < 200
          ln_size = Math.log(size)
          f.puts [churn,size,ln_size].join(" ")
        end
      end
    end
  end
  rfile = File.expand_path("sizevschurn.R", File.dirname(__FILE__))
  output = File.expand_path("../generated/sizevschurnoutput", File.dirname(__FILE__))
  system("R -q --vanilla < #{rfile} > #{output}")
end
