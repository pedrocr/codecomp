require "tmpdir"
require "fileutils"
require "utils"

class SourcesInfo
  attr_reader :distro

  def initialize(distro, repos=["main", "multiverse", "restricted", "universe"])
    @BinToPackage = {}
    @PackageToFile = {}
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
        fileobj.orig = finfo if line.strip.endswith? ".orig.tar.gz"
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
  
  attr_accessor :package, :orig, :diff, :dsc, :directory
  def initialize(package, dir, pkgcache="./pkgcache/")
    @package = package
    @directory = dir
    @pkgcache = pkgcache
  end

  def download(distname, dest_dir=".")
    origfile = get_from_archive(@orig)
    difffile = get_from_archive(@diff)
  
    origdir = @orig.filename[0...-".orig.tar.gz".size]
    origdir.gsub!(package+"_", package+"-")

    FileUtils.mkdir tmpdir = dest_dir+"/"+origdir+"-"+distname+".tmpdir"
    Util.run_cmd "tar -C #{tmpdir} -zxpf #{origfile}"
    tardir = tmpdir+"/"+origdir
    Util.run_cmd "zcat #{difffile} | patch -s -p1 -d #{tardir}"
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
