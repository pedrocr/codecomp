require "utils"

class DummyFile
  # Dummy download to compare to nothing
  def download(dir)
    FileUtils.mkdir_p dir
  end
end

class Comparator
  def self.compare(pkg1, pkg2, sources1, sources2, basetmpdir=nil, resultsdir=nil)
    basetmpdir ||= File.dirname(__FILE__)+"/../tmpdir/#{sources1.distro}_#{sources2.distro}"
    resultsdir ||= File.dirname(__FILE__)+"/../cmpcache/#{sources1.distro}_#{sources2.distro}"
    pkgname = (pkg1 ? pkg1 : "nil")+"#"+(pkg2 ? pkg2 : "nil")
    resultfile = resultsdir+"/"+pkgname
    if !File.exists? resultfile
      FileUtils.mkdir_p resultsdir
      FileUtils.mkdir_p tmpdir = basetmpdir+"/"+pkgname
      file1 = pkg1 ? sources1.package_to_file(pkg1) : DummyFile.new
      file2 = pkg2 ? sources2.package_to_file(pkg2) : DummyFile.new
      file1.download(dir1 = tmpdir+"/"+sources1.distro)
      file2.download(dir2 = tmpdir+"/"+sources2.distro)
      run_cmd_size_of_dir("From:", pkg1, dir1, resultfile)
      run_cmd_size_of_dir("To:", pkg2, dir2, resultfile)
      # Diff exits with code 1 on differences hence the || [... bit
      Util.run_cmd "diff -uNr #{dir1} #{dir2} > #{resultfile}.diff || [ \"$?\" -eq 1 ]"
      Util.run_cmd "echo -n \"diffstat: \" >> #{resultfile}"
      Util.run_cmd "cat #{resultfile}.diff | diffstat -b -f 0 | tail -n 1 >> #{resultfile}"
      Util.run_cmd "echo -n \"diffstat -m: \" >> #{resultfile}"
      Util.run_cmd "cat #{resultfile}.diff | diffstat -m -b -f 0 | tail -n 1 >> #{resultfile}"
      FileUtils.rm resultfile+".diff"
      FileUtils.rm_rf tmpdir
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
