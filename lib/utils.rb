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
end
