class Util
  def self.run_cmd(cmd, exit_on_error=true)
    $stderr.puts "++ Running: #{cmd}"
    r = system(cmd)
    if !r
      $stderr.puts "-- Error Running Command: #{cmd}" 
      exit 1 if exit_on_error
    end
    r
  end

  def self.match_expansion(str, name)
    expr = str.scan(/([^\*\?]+|[\*\?])/).map do |m|
      if m[0] == "*"
        ".*"
      elsif m[0] == "?"
        "."
      else
        Regexp.escape(m[0]) 
      end
    end.join("")
    not Regexp.new("^"+expr+"$").match(name).nil?
  end
end
