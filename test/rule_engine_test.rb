#!/usr/bin/env ruby
$-w = true
require File.dirname(__FILE__)+"/../lib/all"
require 'test/unit'

class RuleEngineTest < Test::Unit::TestCase
  def setup
    @re ||= RuleEngine.new("jaunty", "karmic")
  end

  def teardown
    @re.clear_matchups
  end

  def self.assert_matchup(bin, left, right)
    class_eval %{
      def test_in_line_#{caller[0].split(":")[1]}
        @re.process(["#{bin}"])
        assert(@re.matchups[0] == ["#{left}","#{right}"], 
               "#{bin} did not match as [#{left}, #{right}] (instead \#{@re.matchups[0].inspect})")
      end
    }
  end

  assert_matchup("install-info", "texinfo", "texinfo")
end
