desc "figure out how much of Ubuntu is GNU"

run_R

create_data do
  $stderr.puts "Running gnuinlinux"
  dist1 = "maverick"
  dist2 = "natty"
  sinfo2 = SourcesInfo.new(dist2)

  EXTRA_PACKAGES = {
    :gnu => %w{gnutls26 texinfo binutils gdb eglibc coreutils gnupg gnupg2 mailman tar 
               readline6},
    :kernel => %w{iptables ps3-kboot libvirt u-boot qemu-kvm alsa-driver 
                  syslinux util-linux udev e2fsprogs openhpi reiserfsprogs 
                  reiser4progs libusb net-tools strace elfutils jfsutils xfsdump 
                  xfsprogs crash},
    :bsd => %w{openssh bsdmainutils},
    :gnome => %w{gimp gimp-help gcalctool gnome-vfs gvfs gconf-editor libbonobo 
                 libbonoboui},
    :misc => %w{likewise-open eucalyptus-commons-ext},
    :devel => %w{llvm-2.7 llvm-2.8 boost1.42 gccxml subversion bzr icu valgrind 
                 openssl openldap gwt git tcl8.5 tk8.4 tk8.5 openjdk-6 
                 openjdk-6b18 php5 db4.8 db libxml libxml2 clutter1.0 sqlite sqlite3 imlib2 libnih
                 zlib libjpeg8 clutter-1.0},
    :kde => %w{k3b ktorrent webkit qtwebkit-source},
    :userapps => %w{inkscape digikam ubiquity banshee vim pidgin ghostscript 
                    imagemagick xine-lib libav clamav transmission scribus gftp 
                    fetchmail rsync bogofilter texi2html virt-manager 
                    modemmanager openvpn bouncycastle},
    :baseapps => %w{poppler pulseaudio samba mysql-5.1 bind9 krb5 gstreamer0.10 
                    gst-plugins-good0.10 gst-plugins-base0.10 busybox 
                    sane-backends sudo gpsd postgresql-8.4 gutenprint cups},
    :x11 => %w{mesa},
    :ubuntu => %{installation-guidei usb-creator},
    :debian => %w{synaptic apt-setup base-installer debconf gdebi devscripts 
                  aptitude}
  }

  cats = [:other,:misc,:userapps,:openoffice,:baseapps,:gnome,:kde,:gnu,:debian,
          :ubuntu,:apache,:mozilla,:freedesktop,:bsd,:devel,:x11,:kernel]
  results = {}
  cats.each{|cat| results[cat] = [0,0]}
  
  others = []
  CompResult.each(:dist1 => dist1, :dist2 => dist2) do |cmp|
    section = cmp.to_section||cmp.from_section
    sec = nil
    if cmp.to == "nil"
      sec = nil
    else
      pkg = sinfo2.package_to_file(cmp.to)
      homepage = pkg.homepage||""
      vcsbrowser = pkg.vcsbrowser||""
      maintainer = pkg.maintainer||""
      EXTRA_PACKAGES.each{|s, pkgs| sec = s if pkgs.include? cmp.to}
      if sec
        # We're done
      elsif pkg.priority == "extra"
        sec = nil
      elsif homepage.include? ".gnu.org" or homepage.include? ".fsf.org"
        sec = :gnu
      elsif cmp.to.startswith? "openoffice" or cmp.to.startswith? "libreoffice"
        sec = :openoffice
      elsif ["x11","gnome","kde","kernel"].include? section
        sec = section.to_sym
      elsif homepage.include? ".gnome.org"
        sec = :gnome
      elsif homepage.include? ".apache.org"
        sec = :apache
      elsif homepage.include? ".mozilla.org" or maintainer.include? "mozillateam"
        sec = :mozilla
      elsif homepage.include? ".freedesktop.org"
        sec = :freedesktop
      elsif homepage.include? ".debian.org"
        sec = :debian
      elsif cmp.to.startswith? "partman"
        sec = :debian
      elsif cmp.to.startswith? "qt4-" or cmp.to.startswith? "qt-" or cmp.to.startswith? "kde"
        sec = :kde
      elsif cmp.to.startswith? "gtk" or cmp.to.startswith? "gdk" or cmp.to.startswith? "glib" or cmp.to.startswith? "libgnome"
        sec = :gnome
      elsif cmp.to.startswith? "ubuntu" 
        sec = :ubuntu
      elsif ["python","perl","interpreters","cli-mono"].include? section
        sec = :devel
      elsif ["tex"].include? section
        sec = :userapps
      elsif cmp.to.startswith? "libgnome-"
        sec = :gnome
      elsif cmp.to == "linux"
        sec = :kernel
      elsif cmp.to.startswith? "linux-"
        sec = :kernel
      else
        sec = :other
        others << [cmp.to,cmp.to_loc.to_i,homepage]
      end
    end
    if sec
      results[sec][0] += cmp.to_loc.to_i
      results[sec][1] += (cmp.insertions.to_i+cmp.deletions.to_i)
    end
  end

  puts others.sort{|a,b| a[1] <=> b[1]}[-200..-1].map{|el| el.join(" ")}
  $stderr.puts "#{others.size} package in :others"

  sum = results.values.reduce{|acc, el| [acc[0]+el[0],acc[1]+el[1]]}
  p [results[:gnu][0].to_f/sum[0].to_f,results[:gnu][1].to_f/sum[1].to_f]

  File.open(datafile, "w") do |f|    
    f.puts "LABEL SIZE CHURN"
    cats.each {|cat| f.puts cat.to_s+" "+results[cat].join(" ")}
  end
end
