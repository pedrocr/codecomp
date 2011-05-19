require "tmpdir"
require "fileutils"
require "utils"

class SourceBundle
  attr_reader :src, :exprs, :sinfo, :matches
  def initialize(sinfo, options)
    @sinfo = sinfo
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
    @matches[-1]
  end 

  def section
    sinfo.package_to_file(pkg).section
  end

  def votes
    @matches.map{|m| sinfo.package_to_file(m).votes}.reduce(:+)
  end

  private
  def find_all_matching_srcs(exprs, sinfo)
    matches = Array.new(exprs.size){Array.new}
    sinfo.each do |src| 
      exprs.each_with_index do |e,i| 
        matches[i] << src if Util.match_expansion(e, src)
      end
    end
    matches.flatten
  end
end

class SourcesInfo
  attr_reader :distro
  include Enumerable

  def initialize(distro, opts={})
    @PackageToFile = {}
    @BinToVotes = {}
    @simple_bundles = {}
    @wildcard_bundles = []
    @ignore_srcs = []
    @distro = distro

    #FIXME: use a different file per distro
    if opts[:popconfile]
      parsepopcon(opts[:popconfile])
    else
      parsepopcon(File.dirname(__FILE__)+"/../data/popcon/all")
    end

    repos = opts[:repos] || ["main"]
    if opts[:parsefile]
      parsefile opts[:parsefile]
    else
      repos.each do |repo|
        repofile = "Sources-#{distro}-#{repo}.bz2"
        fullpath = Archive.get("/dists/#{distro}/#{repo}/source/Sources.bz2",
                                 repofile)
        parsefile(fullpath)
      end
    end
  end

  def parsepopcon(filename)
    File.open(filename).each do |line|
      if line.startswith? "Package: "
        s = line.split[1..-1]
        @BinToVotes[s[0]] = s[1].to_i
      end
    end
  end

  def getvotes(bin)
    @BinToVotes[bin] || 0
  end

  def parsefile(filename)
    currpkg = nil
    in_files_section = false
    fileobj = nil
    dir = nil

    simple_attrs = {"Section" => :section, "Homepage" => :homepage, 
                    "Priority" => :priority, "Vcs-Browser" => :vcsbrowser,
                    "Maintainer" => :maintainer, "Directory" => :directory}

    IO.popen("bzcat #{filename}").each do |line|
      if line.include? ":" or line.strip == ""
        in_files_section = false
      end
      if in_files_section
        md5, size, filename = line.split
        fileobj.add_file FileInfo.new(filename, md5, size)
      elsif line.startswith? "Package:"
        currpkg = line.split[1]
        @PackageToFile[currpkg] = fileobj = SourcePkg.new(currpkg,@distro)
      elsif simple_attrs.keys.include?(a = line.split(":")[0].strip)
        fileobj.send(simple_attrs[a].to_s+"=", line.split(":")[1..-1].join(":").strip)
      elsif line.startswith? "Binary:"
        line[8..-1].split(",").each{|bin| fileobj.add_bin(bin.strip, getvotes(bin.strip))}
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

  def ignore_srcs(srcs)
    @ignore_srcs += srcs
  end

  def bin_to_bundle(bin)
    src_to_bundle(bin_to_package(bin))
  end

  def find_ignore_src_match(src)
    @ignore_srcs.map{|e| Util.match_expansion(e, src)}.inject{|a,b| a or b}
  end

  def bundles
    self.map {|src| src_to_bundle(src) if !find_ignore_src_match(src)}
  end

  def src_to_bundle(src)
    return nil if not src
    @wildcard_bundles.each {|b| return b if b.match? src}
    @simple_bundles[src] ||= SourceBundle.new(self, :src=>src)
  end

  def inspect
    to_s
  end
  def to_s
    "<SourcesInfo: #{@distro}>"
  end
end

class FileInfo
  attr_reader :filename, :md5, :size, :type
  def initialize(filename, md5, size)
    @filename = filename
    @md5 = md5
    @size = size    

    split = filename.split(".")
    if split[-1] == 'dsc'
      @type = :dsc
    elsif split[-2] == 'diff'
      @type = :diff
    elsif ["gz","bz2","xz"].include? split[-1]
      @type = :orig
    else
      @type = :unknown
    end
  end
end

class SourcePkg
  SOURCE_EXTS = ["c","cc","cpp","h","rb","py","cs","java","pl","xs","php","sh",
                 "vala","js","d","f","s","patch","diff","dpatch","mm"]  
  PKG_EXTS = {"tar.gz" => "z", "tgz" => "z", "tar.bz2" => "j", "tar.xz" => "J"}

  attr_accessor :package, :distro, :directory, :section, :homepage, :priority, 
                :vcsbrowser, :maintainer
  attr_reader :votes
  def initialize(package, distro, pkgcache="./pkgcache/")
    @package = package
    @directory = nil
    @pkgcache = pkgcache
    @files = []
    @votes = 0
    @distro = distro
  end

  def add_file(finfo)
    @files << finfo
  end

  def add_bin(bin, votes)
    @votes += votes
  end

  def orig
    @files.find{|f| f.type == :orig}
  end
  
  def dsc
    @files.find{|f| f.type == :dsc}
  end

  def download(destdir=".")
    @files.each{|f| get_from_archive(f)}

    #Unpack using dpkg-source
    Util.run_cmd "dpkg-source -x --no-copy #{get_from_archive(dsc)} #{destdir}"

    #Extract all packages from inside the package (complex packages like firefox
    #or openoffice have the upstream packages inside the debian packaging)
    PKG_EXTS.each do |ext, flag|
      IO.popen("find #{destdir} -name \"*.#{ext}\"").each do |file|
        file = file.strip
        Util.run_cmd "tar -C #{File.dirname(file)} -#{flag}xf #{file}"
      end
    end

    #Remove all non-source files
    extensions = SOURCE_EXTS+SOURCE_EXTS.map{|e| e.upcase}
    ext_cond = extensions.map{|e| "-not -name \"*.#{e}\""}.join(" ")
    
    File.open("#{destdir}/deleted_files", "w") do |f|
      ["find #{destdir} -type l",
       "find #{destdir} #{ext_cond} -not -type d"].each do |cmd|
        IO.popen(cmd).each do |line|
          line = line.strip
          if not line.endswith? "deleted_files"
            f.puts line
            FileUtils.rm line
          end
        end
      end
    end
  end

  private 
  def get_from_archive(file)
    Archive.get("/#{@directory}/#{file.filename}", file.filename)
  end
end

class Archive
  BASE_URL="http://archive.ubuntu.com/ubuntu/"
  CACHE_DIR = File.dirname(__FILE__)+"/../pkgcache/"
  NSEC_RETRY = 30

  def self.get(url, filename)
    #FIXME Check md5 if it already exists and at the end
    FileUtils.mkdir_p(CACHE_DIR)
    finalpath = CACHE_DIR+"/"+filename
    if File.exists? finalpath
      Util.info "#{filename} already in cache"
    else
      $stderr.puts "   Downloading #{filename}"
      tmpdir = Dir.tmpdir+"/ubuntu_evolution-"+Process.pid.to_s
      FileUtils.mkdir_p tmpdir
      fullpath = tmpdir+"/"+filename
      cmd = "curl #{Util.verbose ? '-#' : '-s'} -o #{fullpath} #{BASE_URL}/#{url}"  
      while !Util.run_cmd(cmd, false)
        $stderr.puts "Trying again in #{NSEC_RETRY} seconds"
        sleep NSEC_RETRY
      end
      FileUtils.mv fullpath, finalpath
      FileUtils.rmdir tmpdir
    end
    finalpath
  end
end
