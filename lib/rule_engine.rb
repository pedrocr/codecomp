class RuleEngine
  attr_reader :warnings, :errors

  def self.load(filename, s1, s2)
    re = new(s1, s2)
    re.instance_eval(File.read(filename), filename)
    re
  end

  def initialize(sinfo1, sinfo2)
    @sinfo1 = sinfo1
    @sinfo2 = sinfo2
    @ignore_bins = []
    @deleted_in = {}
    @added_in = {}
    @include_srcs = []
    @same_srcs = {}

    @comparison_pairs = {}
    @warnings = 0
    @errors = 0
  end

  def same_src(expr1, *exprs)
    exprs.unshift(expr1)
    @sinfo1.add_wildcard_bundle(exprs)
    @sinfo2.add_wildcard_bundle(exprs)
  end

  def ignore_bin(bin1, *bins)
    @ignore_bins += bins.unshift(bin1)
  end

  def include_src(src1, *srcs)
    @include_srcs += srcs.unshift(src1)
  end

  def deleted_in(dist, src)
    @deleted_in[src] = dist
  end

  def added_in(dist, src)
    @added_in[src] = dist
  end

  def add_comparison(src1, src2)
    @comparison_pairs[[src1,src2]] = true
  end

  def warn(message)
    puts "Warning: #{message}"
    @warnings += 1
  end

  def error(message)
    puts "ERROR: #{message}"
    @errors += 1
  end

  def find_ignore_bin_match(bin)
    @ignore_bins.map{|e| Util.match_expansion(e, bin)}.inject{|a,b| a or b}
  end

  def process_bins(bins)
    dist1 = @sinfo1.distro
    dist2 = @sinfo2.distro
    bins.each do |bin|
      if not find_ignore_bin_match(bin)
        sb1 = @sinfo1.bin_to_bundle(bin)
        sb2 = @sinfo2.bin_to_bundle(bin)
        if sb1 and sb2 and sb1 != sb2
          error "#{bin}: source package #{src1} matches #{expr1} and #{src2} matches #{expr2}"
        else 
          process_srcs(expr, sb1, sb2)
        end
      end
    end
    @same_srcs.each do |expr, values|
      if (values[0] == []) ^ (values[1] == []) # Only one dist matched
        dist_matched = values[0] != [] ? dist1 : dist2
        matches = values[0] != [] ? values[0] : values[1]
        error "same_src expression \"#{expr}\" only matched for #{dist_matched} (matches #{matches})"
      elsif values[0] != [] and values[1] != []
        # Use the highest numbered package from each distro
        process_srcs(expr, values[0].sort[-1], values[1].sort[-1])
      else # values[0] == [] and values[1] == []
        warn "No packages matched same_src expression \"#{expr}\""
      end
    end
  end

  # Process a binary file given the rules and using two SourceInfo objects
  def process_srcs(bin, src1, src2)
    dist1 = @sinfo1.distro
    dist2 = @sinfo2.distro
    if src1 and !src2
      if @deleted_in[src1] == dist2
        add_comparison(src1, nil)
      elsif @sinfo2.include_src? src1
        add_comparison(src1, src2)
      else
        error "#{bin}: #{src1} doesn't exist in #{dist2}, removed?"
      end
    elsif !src1 and src2
      if @sinfo1.include_src? src2
        # Must be an extra binary from the same source
        add_comparison(src2, src2)
      elsif @added_in[src2] == dist2
        add_comparison(nil, src2)
      else
        error "#{bin}: #{src2} doesn't exist in #{dist1}, added?"
      end
    elsif !src1 and !src2
      warn "Package #{bin} doesn't exist in #{dist1} or #{dist2}, ignoring"
    elsif src1 == src2 
      #Normal case
      add_comparison(src1, src2) 
    elsif src1 != src2
      if @deleted_in[src1] == dist2
        add_comparison(src1, nil)
        #For binaries that are moved into an existing source
        add_comparison(src2, src2) if @sinfo1.include_src? src2
      elsif @added_in[src2] == dist2
        add_comparison(nil, src2)
        #For binaries that are moved into a new source
        add_comparison(src1, src1) if @sinfo2.include_src? src1
      else
        warn "#{bin}: Source packages for #{bin} differ (#{src1} in #{dist1}|#{src2} in #{dist2}), comparing anyway"
        add_comparison(src1, src2)
      end
    else
      puts "BUG IN process_bin parser in #{__FILE__}, this should not have happened!"
      exit 100
    end
  end
end
