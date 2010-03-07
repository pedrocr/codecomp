#!/usr/bin/env ruby
$-w = true
require File.dirname(__FILE__)+"/../lib/all"
require 'test/unit'

class SourcesBundleTest < Test::Unit::TestCase
  def setup
    @jaunty ||= SourcesInfo.new("jaunty")
    @karmic ||= SourcesInfo.new("karmic")
  end
  
#  def test_comparisons_exprs
#    bundle1 = SourceBundle.new(@jaunty, :exprs => ["glibc","eglibc"])
#    bundle2 = SourceBundle.new(@karmic, :exprs => ["glibc","eglibc"])
#    assert(bundle1 == bundle2, "#{bundle1} != #{bundle2}")
#    assert(bundle1.hash == bundle2.hash, "#{bundle1} != #{bundle2}")
#  end

#  def test_comparisons_src
#    bundle1 = SourceBundle.new(@jaunty, :src => "texinfo")
#    bundle2 = SourceBundle.new(@karmic, :src => "texinfo")
#    assert(bundle1 == bundle2, "#{bundle1} != #{bundle2}")
#    assert(bundle1.hash == bundle2.hash, "#{bundle1} != #{bundle2}")
#  end

  def test_double_comparisons_exprs
    bundle1a = SourceBundle.new(@jaunty, :exprs => ["glibc","eglibc"])
    bundle2a = SourceBundle.new(@karmic, :exprs => ["glibc","eglibc"])
    bundle1b = SourceBundle.new(@jaunty, :exprs => ["glibc","eglibc"])
    bundle2b = SourceBundle.new(@karmic, :exprs => ["glibc","eglibc"])

    pair1 = [bundle1a, bundle2a]
    pair2 = [bundle1b, bundle2b]

    assert(pair1 == pair2, "#{pair1} != #{pair2}")
    assert(pair1.hash == pair2.hash, "#{pair1} hash != #{pair2} hash")
    assert(pair1.eql?(pair2), "#{pair1} not .eql? to #{pair2}")
  end
end
