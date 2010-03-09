require "tmpdir"
require "fileutils"
require "utils"

class SourceBundle
  attr_reader :src, :exprs, :sinfo, :matches
  def initialize(sinfo, options)
    @src = nil
    if options[:src] 
      @src = options[:src] 
      @matches = [options[:src]]
    elsif options[:exprs]
      @exprs = options[:exprs]
      @matches = find_all_matching_srcs(options[:exprs], sinfo)
    end
  end
  
  def match?(src)
    @matches.include? src
  end

  def to_s
    @src ? @src : @exprs.join("|")
  end

  def ==(sb)
    self.src ? self.src == sb.src : self.exprs == sb.exprs
  end

  def hash
    self.src ? self.src.hash : self.exprs.hash
  end

  def eql?(sb)
    self.src ? self.src.eql?(sb.src) : self.exprs.eql?(sb.exprs)
  end

  def pkg
    @matches.sort[-1]
  end 

  def find_correspondent(sinfo)
    if @src
      if sinfo.include_src? @src
        SourceBundle.new(sinfo, :src => @src)
      else
        nil
      end
    else
      b = SourceBundle.new(sinfo, :exprs => @exprs)
      b.matches.size > 0 ? b : nil
    end
  end

  private
  def find_all_matching_srcs(exprs, sinfo)
    sinfo.find_all{|src| exprs.map{|e| Util.match_expansion(e, src)}.inject{|a,b| a or b}}
  end
end

class SourcesInfo
  attr_reader :distro
  include Enumerable

  def initialize(distro, repos=["main", "multiverse", "restricted", "universe"])
    @BinToPackage = {}
    @PackageToFile = {}
    @simple_bundles = {}
    @wildcard_bundles = []
    @distro = distro

    repos.each do |repo|
      repofile = "Sources-#{distro}-#{repo}.bz2"
      fullpath = Archive.get("/dists/#{distro}/#{repo}/source/Sources.bz2",
                               repofile)
      parsefile(fullpath)
    end
  end

  def parsefile(filename)
    currpkg = nil
    in_files_section = false
    fileobj = nil
    dir = nil

    IO.popen("bzcat #{filename}").each do |line|
      if line.include? ":"
        in_files_section = false 
        fileobj = nil
      end
      if in_files_section
        @PackageToFile[currpkg] = fileobj ||= SourcePkg.new(currpkg, dir)
        md5, size, filename = line.split
        finfo = FileInfo.new(filename, md5, size)
        fileobj.orig = finfo if line.strip.endswith? ".tar.gz"
        fileobj.diff = finfo if line.strip.endswith? ".diff.gz"
        fileobj.dsc = finfo if line.strip.endswith? ".dsc"
      elsif line.startswith? "Package:"
        currpkg = line.split[1]
      elsif line.startswith? "Binary:"
        line.split[1..-1].each{|bin| @BinToPackage[bin.tr(",","")] = currpkg}
      elsif line.startswith? "Directory:"
        dir = line.split[1]
      elsif line.startswith? "Files:"
        in_files_section = true
      end
    end
  end

  def bin_to_package(bin); @BinToPackage[bin]; end
  def package_to_file(pkg); @PackageToFile[pkg]; end
  def include_bin?(bin); @BinToPackage.include? bin; end
  def include_src?(src); @PackageToFile.include? src; end

  def each
    @PackageToFile.keys.each {|k| yield k}
  end

  def add_wildcard_bundle(exprs)
    @wildcard_bundles << SourceBundle.new(self, :exprs=>exprs)
  end

  def bin_to_bundle(bin)
    src_to_bundle(bin_to_package(bin))
  end

  def src_to_bundle(src)
    return nil if not src
    @wildcard_bundles.each {|b| return b if b.match? src}
    @simple_bundles[src] ||= SourceBundle.new(self, :src=>src)
  end
end

class FileInfo
  attr_reader :filename, :md5, :size
  def initialize(filename, md5, size)
    @filename = filename
    @md5 = md5
    @size = size
  end
end

class SourcePkg
  SOURCE_EXTS = ["c","cc","h","rb","py","cs","java","pl", "xs", "php","sh","vala",
                 "xml","po",".js","ui","glade","css","d","desktop","f","html",
                 "yml", ".json", "tex", "txt", "s", "diff", "patch", "dpatch"]  

  attr_accessor :package, :orig, :diff, :dsc, :directory
  def initialize(package, dir, pkgcache="./pkgcache/")
    @package = package
    @directory = dir
    @pkgcache = pkgcache
  end

  def download(distname, dest_dir=".")
    origfile = get_from_archive(@orig)
    difffile = get_from_archive(@diff) if @diff
  
    #Unpack the original file
    origdir = @orig.filename[0...-".orig.tar.gz".size]
    FileUtils.mkdir tmpdir = dest_dir+"/"+origdir+"-"+distname+".tmpdir"
    Util.run_cmd "tar -C #{tmpdir} -zxpf #{origfile}"
    newdir = Dir.entries(tmpdir).find{|d| d != "." && d != ".."}
    tardir = tmpdir+"/"+newdir

    #Apply the diff if it exists
    Util.run_cmd "zcat #{difffile} | patch -s -p1 -d #{tardir}" if @diff

    #Remove all non-source files
    extensions = SOURCE_EXTS+SOURCE_EXTS.map{|e| e.upcase}
    ext_cond = extensions.map{|e| "-not -name \"*.#{e}\""}.join(" ")
    delete_files = File.open("#{tardir}/deleted_files", "w")
    IO.popen("find #{tardir} #{ext_cond} -type f").each do |line|
      line = line.strip
      if not line.endswith? "deleted_files"
        delete_files.puts line
        FileUtils.rm line
      end
    end
    delete_files.close

    #Move directory into its final naming
    finaldir = dest_dir+"/"+origdir+"-"+distname
    FileUtils.mv(tardir, finaldir)
    FileUtils.rmdir tmpdir
    finaldir
  end

  private 
  def get_from_archive(file)
    Archive.get("/#{@directory}/#{file.filename}", file.filename)
  end
end

class Archive
  BASE_URL="http://archive.ubuntu.com/ubuntu/"
  CACHE_DIR = "./pkgcache/"
  NSEC_RETRY = 30

  def self.get(url, filename)
    #FIXME Check md5 if it already exists and at the end
    FileUtils.mkdir_p(CACHE_DIR)
    fullpath = CACHE_DIR+"/"+filename
    if File.exists? fullpath
      $stderr.puts "#{filename} already in cache"
    else
      cmd = "curl -o #{fullpath} #{BASE_URL}/#{url}"  
      while !Util.run_cmd(cmd, false)
        $stderr.puts "Trying again in #{NSEC_RETRY} seconds"
        sleep NSEC_RETRY
      end
    end
    fullpath
  end
end
