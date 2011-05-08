class CompResult
  # c = CompResult.new(["a"],[1])
  # c.a #=> 1
  #
  # This is a wrapper to make the code look pretty when iterating the csv files
  # it probably has atrocious performance as it creates a new object per row
  # and does an instance_eval per cell
  def initialize(names,values)
    names.zip(values).each do |name, value| 
      self.instance_eval "def #{name}; #{value.inspect}; end"
    end
  end
  
  def self.each(opts={})
    DISTPAIRS.each do |dist1, dist2|
      names = nil
      FasterCSV.foreach(GENDIR+"/#{dist1}_#{dist2}_comparisons") do |row|
        if !names
          names = row
        else
          if opts[:with_dists]
            yield CompResult.new(names,row), dist1, dist2
          else
            yield CompResult.new(names,row)
          end
        end
      end
    end       
  end
end

def run_r(file, opts={})
  IO.popen("R --slave --vanilla","w") do |proc|
    proc.puts("pdf(file=\"#{opts[:pdf]}\")") if opts[:pdf]
    proc.puts("attach(read.table(\"#{opts[:datafile]}\", header=TRUE),name=\"datafile\")") if opts[:datafile]
    proc.puts File.open(file).read
    proc.close_write
  end
end
