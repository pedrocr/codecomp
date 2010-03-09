require "utils"

class DummyFile
  # Dummy download to compare to nothing
  def download(sources, basedir)
    dir = basedir+"/nil"
    FileUtils.mkdir_p dir
    dir
  end
end

class Comparator
  def self.compare(pkg1, pkg2, sources1, sources2, basedir=File.dirname(__FILE__)+"/../comparisons/")
    pkgname = (pkg1 ? pkg1 : "nil")+"#"+(pkg2 ? pkg2 : "nil")
    tmpdir = basedir+"/"+pkgname
    if File.exists? tmpdir
      $stderr.puts "Warning: #{tmpdir} already exists, skipping comparison"
    else
      FileUtils.mkdir_p tmpdir
      resultfile = tmpdir+"/results"
      file1 = pkg1 ? sources1.package_to_file(pkg1) : DummyFile.new
      file2 = pkg2 ? sources2.package_to_file(pkg2) : DummyFile.new
      dir1 = file1.download(sources1.distro, tmpdir)
      dir2 = file2.download(sources2.distro, tmpdir)
      run_cmd_size_of_dir("From:", pkg1, dir1, resultfile)
      run_cmd_size_of_dir("To:", pkg2, dir2, resultfile)
      Util.run_cmd("echo -n \"Differences: \" >> #{resultfile}")
      Util.run_cmd("diff -uNr #{dir1} #{dir2} | diffstat -b -f 0 | tail -n 1 >> #{resultfile}")
    end
  end

  private
  def self.run_cmd_size_of_dir(prefix, pkg, dir, resultfile)
    if !pkg
      Util.run_cmd("echo \"#{prefix} nil WithLOC: 0\" >> #{resultfile}")
    else
      Util.run_cmd("echo -n \"#{prefix} #{pkg} WithLOC: \" >> #{resultfile}")
      Util.run_cmd("find #{dir} -type f -print0 | wc -l --files0-from=- | tail -n 1 | cut -f 1 -d ' ' | tr '\n' ' ' >> #{resultfile}")
      Util.run_cmd("echo ' ' >> #{resultfile}")
    end
  end
end
