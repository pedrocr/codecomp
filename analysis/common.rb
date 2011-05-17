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
end

class RTask
  # Defines a task that generates data, runs R scripts to produce plots and
  # output text, and generates pngs with convert from the R pdf plots

  def initialize(file)
    @plots = []
    @pngs = []
    @filename = file
    @name = File.basename(file).split(".")[0]
    eval_file(file)
    mkdirtask = Rake::Task.define_task("mkdir_"+@name){FileUtils.mkdir_p GENDIR+@name}
    @maintask = Rake::Task.define_task(@name => [mkdirtask,datafile]+@plots+@pngs)
    @maintask.add_description @desc if @desc
  end

  def eval_file(file)
    eval(File.read(file), binding, file)
  end

  def datafile
    GENDIR+@name+"/data"
  end

  def rfile
    ANALYSISDIR+@name+".R"
  end

  def desc(str)
    @desc = str
  end

  def run_R(opts={})
    @plots << (output = GENDIR+@name+"/Rplots.pdf")
    Rake::FileTask.define_task(output => [datafile,rfile,__FILE__]) do
      exec_R(rfile, datafile)
    end
  end

  def png(page, name, opts={})
    @pngs << (filename = GENDIR+@name+"/"+name+".png")
    Rake::FileTask.define_task(filename => [@plots,__FILE__]) do
      exec_convert(page,filename,opts)
    end
  end

  def create_data(&f)
    Rake::FileTask.define_task(datafile => [:compare_all_dists, @filename, __FILE__]) do
      f.call
    end
  end

  def exec_R(rfile, dfile)
    $stderr.puts "Running #{rfile}"
    IO.popen("R --slave --vanilla","w+") do |proc|
      proc.puts("pdf(file=\"#{GENDIR}#{@name}/Rplots.pdf\",width=9,height=5)")
      proc.puts("attach(read.table(\"#{dfile}\", header=TRUE),name=\"datafile\")")
      proc.puts File.read(rfile)
      proc.close_write
      output = proc.read
      File.open(GENDIR+@name+"/output","w"){|f| f.write output}
    end
  end

  def exec_convert(page, filename, opts)
    $stderr.puts "Writing #{filename}"
    copts = opts.map{|v| v.split}.flatten
    sh *(["convert","-density","600x600"]+copts+[@plots[0]+"[#{page}]", filename])
  end
end
