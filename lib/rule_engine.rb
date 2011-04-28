class RuleEngine
  def initialize(sinfo1, sinfo2)
    @sinfo1 = sinfo1
    @sinfo2 = sinfo2
    @ignore_srcs = []
    @deleted_in = {}
    @added_in = {}
    @include_srcs = []

    @matchup_pairs = {}

    eval_rules "general"
    eval_rules "#{sinfo1.distro}_#{sinfo2.distro}"
  end

  def same_src(expr1, *exprs)
    exprs.unshift(expr1)
    @sinfo1.add_wildcard_bundle(exprs)
    @sinfo2.add_wildcard_bundle(exprs)
  end

  def ignore_src(src1, *srcs)
    @sinfo1.ignore_srcs(srcs.unshift(src1))
    @sinfo2.ignore_srcs(srcs.unshift(src1))
  end

  def matchups
    @matchup_pairs.map do |key, v| 
      sb1, sb2 = key
      [sb1 ? sb1.pkg : nil, sb2 ? sb2.pkg : nil]
    end
  end

  def clear_matchups
    @matchup_pairs = {}
  end

  def process
    sbs = {}
    @sinfo1.bundles.each{|b| sbs[b.hash] ||= [nil,nil]; sbs[b.hash][0] = b}
    @sinfo2.bundles.each{|b| sbs[b.hash] ||= [nil,nil]; sbs[b.hash][1] = b}
    sbs.values.each do |b1, b2|
      add_matchup(b1, b2) if (b1||b2)
    end
  end

  private
  def add_matchup(sb1, sb2)
    @matchup_pairs[[sb1,sb2]] = true
  end
  
  def eval_rules(name)
    filename = File.dirname(__FILE__)+"/../rules/#{name}.rules"
    self.instance_eval(File.read(filename),filename)
  end
end
