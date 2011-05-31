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
  
  def self.each(opts={}, &block)
    if opts[:dist1] and opts[:dist2]
      iterate_dists(opts[:dist1],opts[:dist2],opts, &block)
    else
      DISTPAIRS.each do |dist1, dist2|
        iterate_dists(dist1,dist2,opts, &block)
      end
    end
  end

  private 
  def self.iterate_dists(dist1,dist2,opts)
    names = nil
    FasterCSV.foreach(GENDIR+"comparisons/#{dist1}_#{dist2}") do |row|
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

class RTask
  # Defines a task that generates data, runs R scripts to produce plots and
  # output text, and generates pngs with convert from the R pdf plots

  def initialize(file)
    @filename = file
    @name = File.basename(file).split(".")[0]
    eval_file(file)
  end

  def datafile(num=1)
    GENDIR+@name+"/data"+num.to_s
  end

  def rfile
    ANALYSISDIR+@name+".R"
  end

  def desc(str)
    @desc = str
  end

  def run_R(opts={})
    @ropts = opts
  end

  def png(page, name, opts={})
    @png_runs[name] = [page,opts]
  end

  def create_data(num=1,&f)
    @ndatas = num
    @data_proc = f
  end

  private
  def eval_file(file)
    @png_runs = {}
    eval(File.read(file), binding, file)

    # Data currently depends on "compare_all_dists" although it doesn't have to
    @datafiles = []
    (1..@ndatas).each do |i|
      @datafiles << datafile(i)
      Rake::FileTask.define_task(datafile(i) => [:compare_all_dists, @filename, __FILE__]) do
        @data_proc.call
      end
    end

    # Plots depend on data
    @plots = []
    if @ropts
      @plots << (output = GENDIR+@name+"/Rplots.pdf")
      Rake::FileTask.define_task(output => @datafiles+[rfile,__FILE__]) do
        exec_R(rfile)
      end
    end

    # Pngs depend on plots
    @pngs = []
    @png_runs.each do |name, opts|
      page,opts = opts
      @pngs << (filename = GENDIR+@name+"/"+name+".png")
      Rake::FileTask.define_task(filename => @plots+[__FILE__]) do
        exec_convert(page,filename,opts)
      end
    end

    # Main tasks
    mkdirtask = Rake::Task.define_task("mkdir_"+@name){FileUtils.mkdir_p GENDIR+@name}
    @maintask = Rake::Task.define_task(@name => [mkdirtask]+@datafiles+@plots+@pngs)
    @maintask.add_description @desc if @desc
  end

  def exec_R(rfile)
    $stderr.puts "Running #{rfile}"
    IO.popen("R --slave --vanilla","w+") do |proc|
      proc.puts("pdf(file=\"#{GENDIR}#{@name}/Rplots.pdf\",width=9,height=5)")
      @datafiles.each do |dfile|
        proc.puts("DATA <- read.table(\"#{dfile}\", header=TRUE)")
        proc.puts("attach(DATA)")
      end
      proc.puts File.read(rfile)
      proc.close_write
      output = proc.read
      File.open(GENDIR+@name+"/output","w"){|f| f.write output}
    end
  end

  def exec_convert(page, filename, opts)
    $stderr.puts "Writing #{filename}"
    copts = opts.map{|v| v.split}.flatten
    sh *(["convert","-density","1000x1000"]+copts+[@plots[0]+"[#{page}]", filename])
  end
end
