class RuleEngine
  def initialize(sinfo1, sinfo2)
    @sinfo1 = sinfo1
    @sinfo2 = sinfo2
    @ignore_bins = []
    @deleted_in = {}
    @added_in = {}
    @include_srcs = []
    @same_srcs = {}

    @matchup_pairs = {}

    eval_rules "general"
    eval_rules "#{sinfo1.distro}_#{sinfo2.distro}"
  end

  def eval_rules(name)
    filename = File.dirname(__FILE__)+"/../rules/#{name}.rules"
    self.instance_eval(File.read(filename),filename)
  end

  def same_src(expr1, *exprs)
    exprs.unshift(expr1)
    @sinfo1.add_wildcard_bundle(exprs)
    @sinfo2.add_wildcard_bundle(exprs)
  end

  def ignore_bin(bin1, *bins)
    @ignore_bins += bins.unshift(bin1)
  end

  #FIXME: Find a way to go from src to bin and find the votes so as to not have
  #       to specify it here
  def include_src(src, votes)
    $stderr.puts "Adding #{src} with #{votes} votes"
    @include_srcs << [src, votes]
  end

  def deleted_in(dist, src)
    @deleted_in[src] = dist
  end

  def added_in(dist, src)
    @added_in[src] = dist
  end

  def add_matchup(sb1, sb2, votes)
    @matchup_pairs[[sb1,sb2]] = votes
  end

  def matchups
    @matchup_pairs.map do |key, votes| 
      sb1, sb2 = key
      [sb1 ? sb1.pkg : nil, sb2 ? sb2.pkg : nil, votes]
    end
  end

  def clear_matchups
    @matchup_pairs = {}
  end

  def find_ignore_bin_match(bin)
    @ignore_bins.map{|e| Util.match_expansion(e, bin)}.inject{|a,b| a or b}
  end

  def process(bins)
    dist1 = @sinfo1.distro
    dist2 = @sinfo2.distro
    bins.each do |bin, votes|
      if not find_ignore_bin_match(bin)
        bundle1 = @sinfo1.bin_to_bundle(bin)
        bundle2 = @sinfo2.bin_to_bundle(bin)
        process_bundles(bin, bundle1, bundle2, votes)
      end
    end
    @include_srcs.each do |is|
      src, votes = is
      $stderr.puts "Bundling #{src} with #{votes} votes"
      process_bundles(src, @sinfo1.src_to_bundle(src), @sinfo2.src_to_bundle(src), votes)
    end
  end

  def deleted_in?(sb, dist)
    key = @deleted_in.keys.find{|k| sb.match? k}
    key and @deleted_in[key] == dist
  end

  def added_in?(sb, dist)
    key = @added_in.keys.find{|k| sb.match? k}
    key and @added_in[key] == dist
  end

  # Given two source bundles from a given binary file generate the pairings
  def process_bundles(bin, sb1, sb2, votes)
    dist1 = @sinfo1.distro
    dist2 = @sinfo2.distro
    if sb1 and !sb2
      if deleted_in? sb1, dist2
        add_matchup(sb1, nil, votes)
      elsif newsb2 = sb1.find_correspondent(@sinfo2)
        add_matchup(sb1, newsb2, votes)
      else
        Util.error "#{bin}: #{sb1} doesn't exist in #{dist2}, removed?"
      end
    elsif !sb1 and sb2
      if newsb1 = sb2.find_correspondent(@sinfo1)
        # Must be an extra binary from the same source
        add_matchup(newsb1, sb2, votes)
      elsif added_in? sb2, dist2
        add_matchup(nil, sb2, votes)
      else
        Util.error "#{bin}: #{sb2} doesn't exist in #{dist1}, added?"
      end
    elsif !sb1 and !sb2
      #Util.warn "Package #{bin} doesn't exist in #{dist1} or #{dist2}, ignoring"
    elsif sb1 == sb2 
      #Normal case
      add_matchup(sb1, sb2, votes) 
    elsif sb1 != sb2
      if deleted_in? sb1, dist2
        add_matchup(sb1, nil, votes)
        #For binaries that are moved into an existing source
        add_matchup(newsb1, sb2, votes) if newsb1 = sb2.find_correspondent(@sinfo1)
      elsif added_in? sb2, dist2
        add_matchup(nil, sb2, votes)
        #For binaries that are moved into a new source
        add_matchup(sb1, newsb2, votes) if newsb2 = sb1.find_correspondent(@sinfo2)
      else
        Util.warn "#{bin}: Source packages for #{bin} differ (#{sb1} in #{dist1}|#{sb2} in #{dist2}), comparing anyway"
        add_matchup(sb1, sb2, votes)
      end
    else
      puts "BUG IN process_bin parser in #{__FILE__}, this should not have happened!"
      exit 100
    end
  end
end
