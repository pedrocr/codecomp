desc "Mass compare packages from two dists"
task :mass_compare, [:dist1, :dist2] do |t, args|
  mass_compare(args.dist1, args.dist2)
end

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

  cmpfile = File.dirname(__FILE__)+"/../data/#{dist1}_#{dist2}_comparisons"
  $stderr.puts "Writing #{cmpfile}"
  File.open(cmpfile, 'w') do |f|
    f.puts ['from', 'to', 'from_loc', 'to_loc', 'from_votes', 'to_votes', 
            'files_changed', 'insertions', 'deletions'].join(',')
    matchups.each do |from, to|
      from ||= "nil"
      to ||= "nil"
      filename = File.dirname(__FILE__)+"/../comparisons/#{dist1}_#{dist2}/#{from}\##{to}"
      content = File.open(filename).readlines
      from_loc = read_loc(content[0])
      to_loc = read_loc(content[1])
      from_votes = (from == "nil" ? 0 : sinfo1.src_to_bundle(from).votes)
      to_votes = (to == "nil"  ? 0 : sinfo2.src_to_bundle(to).votes)
      files_changed = read_diffstat(content[2], "files changed")
      insertions = read_diffstat(content[2], "insertions")
      deletions = read_diffstat(content[2], "deletions")
      f.puts [from, to, from_loc, to_loc, from_votes, to_votes, 
              files_changed, insertions, deletions].join(',')
    end
  end
  $stderr.puts "Finished comparing #{dist1} with #{dist2}"
end
