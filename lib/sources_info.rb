require "tmpdir"
require "fileutils"

class SourcesInfo
  def initialize(filename)
    @BinToPackage = {}
    @PackageToFile = {}

    currpkg = nil
    in_files_section = false
    fileobj = nil
    dir = nil

    File.open(filename).each do |line|
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
  NSEC_RETRY = 30

  attr_accessor :package, :orig, :diff, :dsc, :directory, :pkgcache
  def initialize(package, dir, pkgcache="./pkgcache/")
    @package = package
    @directory = dir
    @pkgcache = pkgcache
  end

  def download(dest_dir=".")
    get_from_archive(@orig)
    get_from_archive(@diff)
  
    run_cmd "tar -C #{dest_dir} -zxpf #{pkgcache}/#{@orig.filename}"
    origdir = @orig.filename[0...-".orig.tar.gz".size]
    origdir.gsub!(package+"_", package+"-")
    origdir = dest_dir+"/"+origdir
    run_cmd "zcat #{pkgcache}/#{@diff.filename} | patch -p1 -d #{origdir}"
  end

  private

  def get_from_archive(file)
    #FIXME Check md5 if it already exists and at the end
    FileUtils.mkdir_p(@pkgcache)
    if File.exists? @pkgcache+"/"+file.filename
      $stderr.puts "#{file.filename} already in cache"
    else
      cmd = "wget http://archive.ubuntu.com/ubuntu/#{directory}/#{file.filename}"
      cmd += " -nv -O #{@pkgcache}/#{file.filename}"
      while !run_cmd(cmd, false)
        $stderr.puts "Trying again in #{NSEC_RETRY} seconds"
        sleep NSEC_RETRY
      end
    end
  end

  def run_cmd(cmd, exit_on_error=true)
    $stderr.puts "++ Running: #{cmd}"
    r = system(cmd)
    if !r
      $stderr.puts "-- Error Running Command: #" 
      exit 1 if exit_on_error
    end
    r
  end
end
