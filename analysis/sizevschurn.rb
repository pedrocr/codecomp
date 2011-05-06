desc "predict code churn based on size"
task :sizevschurn => [:compare_all_dists] do
  tmpfile = TMPDIR+"/sizevschurn"

  File.open(tmpfile, "w") do |f|
    f.puts "CHURN LN_SIZE"
    CompResult.each do |cmp|
      if cmp.from != "nil" and cmp.to != "nil"
        size = (cmp.from_loc.to_i+cmp.to_loc.to_i)/2
        churn = (cmp.insertions.to_i+cmp.deletions.to_i).to_f/size.to_f*100
        # Eliminate packages where commonality seems to be so low churn 
        # is a very bad measure. 200% churn comes from all the "from" package
        # being deletions and all the "to" package being insertions
        if size != 0 and churn < 200
          ln_size = Math.log(size)
          f.puts [churn,ln_size].join(" ")
        end
      end
    end
  end
  rfile = File.expand_path("sizevschurn.R", File.dirname(__FILE__))
  output = File.expand_path("../generated/sizevschurnoutput", File.dirname(__FILE__))
  system("R -q --vanilla < #{rfile} > #{output}")

  FileUtils.rm_f tmpfile
end
