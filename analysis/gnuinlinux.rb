desc "figure out how much of Ubuntu is GNU"

run_R

create_data do
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
                     apparmor v4lutils mdadm binfmt-support ecryptfs-utils
                     kexec-tools linux-ntfs squashfs-tools},
    :bsd => %w{openssh bsdmainutils},
    :gnome => %w{gimp gimp-help gcalctool gnome-vfs gvfs gconf-editor libbonobo 
                 libbonoboui},
    :misc => %w{likewise-open eucalyptus-commons-ext rpm},
    :java => %{openjdk-6b18},
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
    :x11 => %w{mesa},
    :ubuntu => %{installation-guidei usb-creator upstart},
    :debian => %w{synaptic apt-setup base-installer debconf gdebi devscripts 
                  aptitude apt tasksel debian-installer},
    :ignore => %w{linux-backports-modules-2.6.38 llvm-2.7 openjdk-6}
  }

  cats = [:other,:misc,:userapps,:openoffice,:baseapps,:java,:gnome,:kde,:gnu,:debian,
          :ubuntu,:apache,:mozilla,:freedesktop,:bsd,:devel,:x11,:kernelaid,:kernel]
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
      elsif ["x11","gnome","kde"].include? section
        sec = section.to_sym
      elsif ["tex"].include? section
        sec = :userapps
      elsif cmp.to.startswith? "ibus-" or cmp.to == "ibus"
        sec = :baseapps
      else
        sec = :other
        others << [cmp.to,cmp.to_loc.to_i,homepage]
      end
    end
    if sec and sec != :ignore
      results[sec][0] += cmp.to_loc.to_i
      results[sec][1] += (cmp.insertions.to_i+cmp.deletions.to_i)
    end
  end

  #puts others.sort{|a,b| a[1] <=> b[1]}.reverse.map{|el| el.join(" ")}
  #$stdout.flush
  #$stderr.puts "#{others.size} package in :others"

  total = results.values.reduce{|a,b| [a[0]+b[0],a[1]+b[1]]}

  finalcats = [:gnu, :kernel, :gnome, :kde, :mozilla, :java, :openoffice]

  File.open(datafile, "w") do |f|    
    f.puts "LABEL SIZE CHURN"
    finalcats.each {|cat| f.puts cat.to_s+" "+results[cat].join(" ")}
    f.puts "total "+total.join(" ")
  end
end
