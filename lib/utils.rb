class Util
  @@warnings = 0
  @@errors = 0
  @@verbose = true

  def self.run_cmd(cmd, exit_on_error=true)
    $stderr.puts "++ Running: #{cmd}" if @@verbose
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

  def self.info(message)
    $stderr.puts "Info: #{message}" if @@verbose
  end

  def self.warn(message)
    $stderr.puts "Warning: #{message}" if @@verbose
    @@warnings += 1
  end
  def self.warnings; @@warnings; end

  def self.error(message)
    $stderr.puts "ERROR: #{message}"
    @@errors += 1
  end
  def self.fatal_error(message)
    $stderr.puts "FATAL ERROR: #{message}"
    exit 2
  end

  def self.errors; @@errors; end

  def self.verbose; @@verbose; end
end
