class SourcesInfo
  def initialize(filename)
    @BinToPackage = {}
    @PackageToOrigFile = {}
    @PackageToDiffFile = {}

    currpkg = nil
    in_files_section = false

    File.open(filename).each do |line|
      in_files_section = false if line.include? ":"
      if in_files_section
        @PackageToOrigFile[currpkg] = line.split[2] if line.strip.endswith? ".orig.tar.gz"
        @PackageToDiffFile[currpkg] = line.split[2] if line.strip.endswith? ".diff.gz"
      elsif line.startswith? "Package:"
        currpkg = line.split[1]
      elsif line.startswith? "Binary:"
        line.split[1..-1].each{|bin| @BinToPackage[bin.tr(",","")] = currpkg}
      elsif line.startswith? "Files:"
        in_files_section = true
      end
    end
  end

  def bin_to_package(bin); @BinToPackage[bin]; end
  def package_to_orig(pkg); @PackageToOrigFile[pkg]; end
  def package_to_diff(pkg); @PackageToDiffFile[pkg]; end
end

