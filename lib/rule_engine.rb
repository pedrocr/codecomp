class RuleEngine
  def self.load(filename)
    re = new
    re.instance_eval(File.read(filename), filename)
    re
  end
  
  def self.match(str, name)
    expr = str.gsub(/([\[\]\(\)\^\$\+\{\}\|])\\/, '\\1').
               gsub(/\./, '\.').
               gsub(/\?/, '.').
               gsub(/\*/, '.*').
               sub(/^/, '^').
               sub(/$/, '$')
    not Regexp.new(expr).match(name).nil?
  end

  def initialize
    @ignore_bins = {}
    @deleted_in = {}
    @added_in = {}
    @include_srcs = []
    @same_bins = []

    @comparison_pairs = {}
  end

  def same_bin(bin1, bin2, *bins)
    @same_bins << [bin1, bin2] + bins
  end

  def ignore_bin(*bins)
    bins.each {|b| @ignore_bins{b} = true}
  end

  def include_src(*srcs)
    @include_srcs += srcs
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

  # Process a binary file given the rules and using two SourceInfo objects
  def process_bin(bin, si1, si2)
    return if @ignore_bins.include? bin

    src1 = s1.bin_to_package(bin)
    src2 = s2.bin_to_package(bin)
    dist1 = si1.name
    dist2 = si2.name
  
    if src1 and !src2
      if @deleted_in[src1] == dist2
        add_comparison(src1, nil)
      else
        $stderr.puts "WARNING: Possible removed source package #{src2} in #{dist2}, ignoring"
      end
    elsif !src1 and src2
      if s1.include_src? src2
        # Must be an extra binary from the same source
        add_comparison(src2, src2)
      elsif @added_in[src2] == dist2
        add_comparison(nil, src2)
      else
        $stderr.puts "WARNING: Possible added source package #{src2} in #{dist2}, ignoring"
      end
    elsif !src1 and !src2
      $stderr.puts "WARNING: Package #{bin} doesn't exist in #{dist1} or #{dist2}, ignoring"
    elsif same_bins(src1, src2)
      add_comparison(src1, src2)
    elsif src1 != src2
      puts "WARNING: Source packages for #{bin} differ (#{src1} in #{dist1}|#{src2} in #{dist2}), ignoring"
    else
      $stderr.puts "BUG IN process_bin parser in #{__FILE__}, this should not have happened!"
      exit 100
    end
  end
end
