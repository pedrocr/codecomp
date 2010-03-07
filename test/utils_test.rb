#!/usr/bin/env ruby
$-w = true
require File.dirname(__FILE__)+"/../lib/all"
require 'test/unit'

class UtilsTest < Test::Unit::TestCase
  @@test_num = 0  

  def self.assert_match(str, name)
    class_eval %{
      def test_in_line_#{caller[0].split(":")[1]}
        assert(Util.match_expansion("#{str}","#{name}") == true, "#{name} did not match #{str}")
      end
    }
  end
  def self.assert_nomatch(str, name)
    class_eval %{
      def test_in_line_#{caller[0].split(":")[1]}
        assert(Util.match_expansion("#{str}","#{name}") == false, "#{name} matched #{str}")
      end
    }
  end

  assert_match("foo[]{}\\+-/", "foo[]{}\\+-/")
  assert_match("foo*","foobar")
  assert_match("*bar","foobar")
  assert_nomatch("foo*","barfoobar")
  assert_nomatch("*foo","barfoobar")
  assert_match("*bar","foobar")
  assert_match("foo?","foob")
  assert_nomatch("foo?","fooba")
  assert_nomatch("foo?","foobar")
  assert_nomatch("foo*", nil)
end

