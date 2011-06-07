desc "figure out how much of Ubuntu is GNU"

run_R
png 0, "totalsplit", ["-trim", "-geometry 9999x300","-bordercolor white","-border 10x10"]
pdf 0, "totalsplit"
png 1, "gnusplit", ["-trim", "-geometry 9999x300","-bordercolor white","-border 10x10"]
pdf 1, "gnusplit"

create_data(2) do
  $stderr.puts "Running gnuinlinux"
  dist1 = "maverick"
  dist2 = "natty"
  sinfo2 = SourcesInfo.new(dist2)

  EXTRA_PACKAGES = {
    :gnu => %w{gnutls26 texinfo binutils gdb eglibc coreutils gpgme1.0 gnupg gnupg2 mailman tar 
               readline6 parted grub},
    :kernel => %w{linux},
    :kernelaid => %w{iptables libvirt qemu-kvm alsa-driver 
                     syslinux util-linux udev e2fsprogs openhpi reiserfsprogs 
                     reiser4progs libusb net-tools strace elfutils jfsutils xfsdump 
                     xfsprogs crash openipmi lvm2 apparmor ocfs2-tools alsa-lib
                     v4lutils mdadm binfmt-support ecryptfs-utils kexec-tools 
                     linux-ntfs squashfs-tools},
    :bsd => %w{openssh bsdmainutils},
    :gnome => %w{gimp gimp-help gcalctool gnome-vfs gvfs gconf-editor libbonobo 
                 libbonoboui},
    :misc => %w{likewise-open eucalyptus-commons-ext rpm},
    :java => %w{openjdk-6b18},
    :devel => %w{llvm-2.8 boost1.42 gccxml subversion bzr valgrind git tcl8.5 
                 tk8.4 tk8.5  php5 cmake cpu-checker groovy puppet nasm re2c 
                 mono-tools linux86 libsigc++-2.0},
    :kde => %w{k3b ktorrent libktorrent konq-plugins webkit qtwebkit-source},
    :userapps => %w{inkscape digikam ubiquity banshee vim pidgin ghostscript 
                    imagemagick xine-lib libav clamav transmission scribus gftp 
                    fetchmail rsync bogofilter texi2html virt-manager 
                    modemmanager openvpn bouncycastle bacula graphviz avogadro
                    mutt moin nagios3 lftp cdrkit freeradius tiff vorbis-tools
                    nano nut tcpdump},
    :baseapps => %w{poppler pulseaudio samba mysql-5.1 bind9 krb5 gstreamer0.10 
                    gst-plugins-good0.10 gst-plugins-base0.10 busybox 
                    sane-backends sudo gpsd postgresql-8.4 gutenprint cups
                    virtuoso-opensource packagekit lapack dom4j icu openssl 
                    openldap gwt sqlite sqlite3 imlib2 libnih zlib libjpeg8 
                    clutter-1.0 cairo libgphoto2 libxml libxml2 clutter1.0 db4.8 
                    db fftw3 postfix libsdl1.2 directfb ntp flac dovecot 
                    libsamplerate net-snmp saxonb libvigraimpex quagga 
                    wpasupplicant exiv2 libxslt bluez exim4 pam twisted squid
                    xapian-bindings xapian-core drools openbabel hsqldb curl
                    ncurses hplip avahi pango1.0 gegl nas blas foomatic-db
                    libvorbis orbit2 klibc gupnp u-boot},
    :xorg => %w{mesa},
    :ubuntu => %w{installation-guide usb-creator upstart},
    :debian => %w{synaptic apt-setup base-installer debconf gdebi devscripts 
                  aptitude apt tasksel debian-installer},
    :ignore => %w{linux-backports-modules-2.6.38 llvm-2.7 openjdk-6}
  }

  # Make sure no package was classified twice and that all lists of packages are
  # actually arrays. %w{ is easy to mistake for %{
  reversed = {}
  EXTRA_PACKAGES.each do |s, pkgs|
    Util.fatal_error "EXTRA_PACKAGES for #{s} not Array" if pkgs.class != Array
    pkgs.each do |p|
      if reversed[p]
        Util.fatal_error "pkg #{p} classified both as #{reversed[p]} and #{s}"
      else
        reversed[p] = s
      end
    end
  end

  cats = [:other,:misc,:userapps,:libreoffice,:baseapps,:java,:gnome,:kde,:gnu,:debian,
          :ubuntu,:apache,:mozilla,:freedesktop,:bsd,:devel,:xorg,:kernelaid,:kernel]
  results = {}
  gnupkgs = {}
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
        sec = :libreoffice
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
      elsif ["vcs","python","perl","interpreters","cli-mono"].include? section
        sec = :devel
      elsif ["gnome","kde"].include? section
        sec = section.to_sym
      elsif ["tex"].include? section
        sec = :userapps
      elsif ["x11"].include? section
        sec = :xorg
      elsif cmp.to.startswith? "ibus-" or cmp.to == "ibus"
        sec = :baseapps
      else
        sec = :other
        others << [cmp.to,cmp.to_loc.to_i,homepage]
      end
    end
    size = cmp.to_loc.to_i
    churn = cmp.insertions.to_i+cmp.deletions.to_i

    if sec == :gnu
      gnupkgs[cmp.to] = [size,churn]
    end

    if sec and sec != :ignore
      results[sec][0] += size
      results[sec][1] += churn
    end
  end

  #puts others.sort{|a,b| a[1] <=> b[1]}.reverse.map{|el| el.join(" ")}
  #$stdout.flush
  #$stderr.puts "#{others.size} package in :others"



  finalcats = [:gnu, :kernel, :kde, :mozilla, :gnome, :java, :xorg]
  sum2 = Proc.new{|a,b| [a[0]+b[0],a[1]+b[1]]}

  finalresults = {}
  finalcats.each {|cat| finalresults[cat]=results[cat]}
  finalresults[:kernel] = sum2.call(results[:kernel],results[:kernelaid])

  total = results.values.reduce(&sum2)
  considered = finalresults.values.reduce(&sum2)
  finalresults[:other] = [total[0]-considered[0],total[1]-considered[1]]

  File.open(datafile(1), "w") do |f|    
    f.puts "LABEL SIZE CHURN"
    (finalcats+[:other]).each {|cat| f.puts cat.to_s+" "+finalresults[cat].join(" ")}
  end

  finalpkgs = {:gcc => ["gcc-4.5","gcj-4.5"], :gdb => "gdb", :binutils => "binutils",
               :glibc => "eglibc", :gettext => "gettext", :emacs => "emacs23",
               :coreutils => "coreutils", :grub => "grub2", :gnutls => "gnutls26",
               :gnupg => ["gnupg2","gpgme1.0"], :gsl => "gsl",
               :libunistring => "libunistring",:mailman=>"mailman"}
  finalresults = []
  finalpkgs.each do |name, pkg|
    pkgs = ((pkg.instance_of? Array) ? pkg : [pkg])
    finalresults << [name, pkgs.map{|pkg| gnupkgs[pkg]}.reduce(&sum2)]
  end
  total = gnupkgs.values.reduce(&sum2)
  considered = finalresults.map{|n,vals| vals}.reduce(&sum2)
  finalresults.sort!{|a,b| a[1][0] <=> b[1][0]}
  finalresults << [:other, [total[0]-considered[0],total[1]-considered[1]]]

  File.open(datafile(2), "w") do |f|    
    f.puts "PKG_LABEL PKG_SIZE PKG_CHURN"
    finalresults.each{|pkg, values| f.puts pkg.to_s+" "+values.join(" ")}
  end
end
