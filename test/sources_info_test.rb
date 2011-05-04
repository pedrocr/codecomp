#!/usr/bin/env ruby
$-w = true
require File.dirname(__FILE__)+"/../lib/all"
require 'test/unit'

class SourcesInfoTest < Test::Unit::TestCase
  def test_double_comparisons_exprs
    @jaunty ||= SourcesInfo.new("jaunty")
    @karmic ||= SourcesInfo.new("karmic")

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

  def test_parse
    popcon = File.dirname(__FILE__)+"/popcon.test"
    sources = File.dirname(__FILE__)+"/sources-info.test.bz2"
    sinfo = SourcesInfo.new("jaunty", :popconfile => popcon, :parsefile => sources)

    bundle = sinfo.src_to_bundle("dpkg")
    assert_instance_of SourceBundle, bundle
    assert_equal 111, bundle.votes 
  end
end
