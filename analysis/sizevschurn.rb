module SizeVsChurn
  PDF = GENDIR+"/sizevschurn.pdf"
  OUTPUT = GENDIR+"/sizevschurnoutput"
  RFILE = File.expand_path("sizevschurn.R", File.dirname(__FILE__))
  DATAFILE = GENDIR+"/sizevschurndata"

  desc "predict code churn based on size"
  task :sizevschurn => [PDF,OUTPUT]

  [PDF,OUTPUT].each do |f|
    file PDF => [DATAFILE,RFILE] do |t|
      run_r RFILE, :datafile => DATAFILE, :pdf => PDF, :output => OUTPUT
    end
  end

  file DATAFILE => [:compare_all_dists, __FILE__] do
    File.open(DATAFILE, "w") do |f|
      f.puts "CHURN SIZE"
      CompResult.each do |cmp|
        if cmp.from != "nil" and cmp.to != "nil"
          size = cmp.from_loc.to_f
          churn = (cmp.insertions.to_i+cmp.deletions.to_i).to_f/size*100/2

          # (churn < 100) Eliminate packages where commonality seems to be so low 
          # churn isn't measuring anything. 100% churn comes from cases where 
          # there is really no commonality and everything is deemed rewritten. 
          #   (Note that since churn is calculated as percentage of from_loc it 
          #    can be >100 if a lot of new code is added. This seems rare enough
          #    to not matter)
          #
          # (churn > 0) Ignore packages with no changes and avoid log(0) if doing
          # log(CHURN) in R
          if churn < 100 and churn > 0
            f.puts [churn,size].join(" ")
          end
        end
      end
    end
  end
end
