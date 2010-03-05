require "utils.rb"

class Comparator
  def self.compare(pkgname, sources1, sources2)
    file1 = sources1.package_to_file(pkgname)
    file2 = sources2.package_to_file(pkgname)

    with_tmp_dirs(pkgname) do |tmpdir|
      dir1 = file1.download(sources1.distro, tmpdir)
      dir2 = file2.download(sources2.distro, tmpdir)
      Util.run_cmd("diff -r #{dir1} #{dir2} | diffstat -b -f 0 | tail -n 1")
    end
  end

  private
  def self.with_tmp_dirs(pkgname)
    #tmpdir = Dir.tmpdir+"/"+Process.pid.to_s+"/"+@package
    tmpdir = Dir.tmpdir+"/ubuntu_evolution/"+pkgname
    FileUtils.rm_rf tmpdir
    FileUtils.mkdir_p tmpdir
    yield tmpdir
    #FileUtils.rm_rf tmpdir
  end
end
