desc "Mass compare packages from two dists"
task :mass_compare, [:dist1, :dist2] do |t, args|
  mass_compare(args.dist1, args.dist2)
end

DISTPAIRS.each do |d1,d2|
  file GENDIR+"/comparisons/#{d1}_{d2}" do
    $stderr.puts "Comparing #{d1} with #{d2}"
    mass_compare(d1,d2)
  end
end

desc "Compare all distributions"
task :compare_all_dists => DISTPAIRS.map{|d1,d2| File.expand_path("comparisons/#{d1}_#{d2}",GENDIR)}

def mass_compare(dist1, dist2)
  sinfo1 = SourcesInfo.new(dist1)
  sinfo2 = SourcesInfo.new(dist2)
  re = RuleEngine.new(sinfo1, sinfo2)
  re.process

  $stderr.puts "Finished determining package matchups, #{Util.errors} errors and #{Util.warnings} warnings"
  if Util.errors > 0 || Util.warnings > 0
    $stderr.puts "Aborting due to errors or warnings in package matchups, correct those to advance"
    exit 1
  end
  $stderr.puts "Success!! Proceeding with comparison"

  matchups = re.matchups
  matchups.each_with_index do |match, i|
    s1, s2 = match
    $stderr.puts "Comparison #{i+1}/#{matchups.size}: #{s1 ? s1 : "nil"} with #{s2 ? s2 : "nil"}"
    Comparator.compare(s1, s2, sinfo1, sinfo2)
  end

  def read_loc(str)
    str.strip!
    str.split(" ")[-1].to_i
  end

  def read_diffstat(str, pattern)
    match = str.match(Regexp.new("(\\d*) "+pattern))
    match ? match[1].to_i : 0
  end

  def get_votes_section(sinfo, pkg)
    return [0,''] if !pkg or pkg == "nil"
    bundle = sinfo.src_to_bundle(pkg)
    [bundle.votes, bundle.section]
  end

  cmpdir = File.dirname(__FILE__)+"/../generated/comparisons/"
  FileUtils.mkdir_p cmpdir  
  cmpfile = File.expand_path("#{dist1}_#{dist2}", cmpdir)
  $stderr.puts "Writing #{cmpfile}"
  File.open(cmpfile, 'w') do |f|
    f.puts ['from', 'to', 'from_section', 'to_section', 'from_loc', 'to_loc', 
            'from_votes', 'to_votes', 'files_changed', 'insertions', 'deletions'].join(',')
    matchups.each do |from, to|
      from ||= "nil"
      to ||= "nil"
      filename = File.dirname(__FILE__)+"/../cmpcache/#{dist1}_#{dist2}/#{from}\##{to}"
      content = File.open(filename).readlines
      from_loc = read_loc(content[0])
      to_loc = read_loc(content[1])
      from_votes, from_section = get_votes_section(sinfo1, from)
      to_votes, to_section = get_votes_section(sinfo2, to)
      files_changed = read_diffstat(content[2], "files changed")
      insertions = read_diffstat(content[2], "insertions")
      deletions = read_diffstat(content[2], "deletions")
      f.puts [from, to, from_section, to_section, from_loc, to_loc, from_votes, to_votes, 
              files_changed, insertions, deletions].join(',')
    end
  end
  $stderr.puts "Finished comparing #{dist1} with #{dist2}"
end
