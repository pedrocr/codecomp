require "faster_csv"

module SectionSplit
  PDF = GENDIR+"/sectionsplit.pdf"
  RFILE = File.expand_path("sectionsplit.R", File.dirname(__FILE__))
  DATAFILE = GENDIR+"/sectionsplitdata"

  desc "plot sections by code churn"
  task :sectionsplit => [PDF]

  file PDF => [DATAFILE,RFILE] do |t|
    run_r RFILE, :datafile => DATAFILE, :pdf => PDF
  end

  file DATAFILE => [:compare_all_dists,__FILE__] do |t|
    churns = {}

    types = {}
    ["cli-mono","devel","embedded","interpreters","java","libdevel","libs",
     "metapackages","oldlibs","perl","python","shells"].each{|s| types[s] = :base}
    ["kernel","admin","debian-installer"].each{|s| types[s] = :core}
    ["comm","database","doc","editors","fonts","games","gnome","graphics","kde",
     "mail","math","misc","net","news","otherosfs","science","sound","tex","text",
     "utils","vcs","video","web","x11","zope"].each{|s| types[s] = :user}

    CompResult.each(:with_dists => :true) do |cmp, dist1, dist2|
      if cmp.from_section && cmp.to_section and cmp.from_section != cmp.to_section
        Util.warn "#{cmp.from} has section #{cmp.from_section} and #{cmp.to} has section #{cmp.to_section}"
      end
      section = cmp.to_section||cmp.from_section
      type = types[section]
      Util.fatal_error("No such section #{section} in correspondence") if !type
      churns[type] ||= {}
      churns[type]["#{dist1}_#{dist2}"] ||= 0
      churns[type]["#{dist1}_#{dist2}"] += (cmp.insertions.to_i+cmp.deletions.to_i)
    end

    File.open(t.name, "w") do |f|    
      f.puts "CORE BASE USER"
      DISTPAIRS.each do |d1, d2|
        f.puts([:core,:base,:user].map{|t| churns[t]["#{d1}_#{d2}"]||0}.join(" "))
      end
    end
  end
end
