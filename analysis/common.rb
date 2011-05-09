require 'faster_csv'

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
      FasterCSV.foreach(GENDIR+"/comparisons/#{dist1}_#{dist2}") do |row|
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

class RTask
  def initialize(file)
    @outputs = []
    @filename = file
    @name = File.basename(file).split(".")[0]
    eval_file(file)
    mkdirtask = Rake::Task.define_task("mkdir_"+@name){FileUtils.mkdir_p GENDIR+"/"+@name}
    @maintask = Rake::Task.define_task(@name => [mkdirtask]+@outputs)
    @maintask.add_description @desc if @desc
  end

  def eval_file(file)
    eval(File.read(file), binding, file)
  end

  def datafile
    GENDIR+"/"+@name+"/data"
  end

  def rfile
    ANALYSISDIR+"/"+@name+".R"
  end

  def desc(str)
    @desc = str
  end

  def run_R(opts={})
    if not (opts[:output]||opts[:pdf])
      Util.fatal_error "run_R without :output or :plot, are you just trying to heat up the room?"
    end

    opts.each do |k,v|
      @outputs << (output = GENDIR+"/"+@name+"/"+v)
      Rake::FileTask.define_task(output => [datafile,rfile]) do
        exec_R rfile, opts.merge(:datafile => datafile)
      end
    end
  end

  def create_data(&f)
    Rake::FileTask.define_task(datafile => [:compare_all_dists, @filename]) do
      f.call
    end
  end

  def exec_R(file, opts={})
    $stderr.puts "Running #{file}"

    IO.popen("R --slave --vanilla","w+") do |proc|
      proc.puts("pdf(file=\"#{GENDIR}/#{@name}/#{opts[:pdf]}\")") 
      proc.puts("attach(read.table(\"#{opts[:datafile]}\", header=TRUE),name=\"datafile\")") if opts[:datafile]
      proc.puts File.open(file).read
      proc.close_write
      output = proc.read
      File.open(GENDIR+"/"+@name+"/"+opts[:output],"w"){|f| f.write output} if opts[:output]
    end
  end
end
