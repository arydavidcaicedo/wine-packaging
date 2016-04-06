{{ __filename = __filename if package_boot else None }}
{{
	output = "%s-%s" % (package, package_version)
	output += "-%s" % package_release if package_release != "" else ""
}}
#!/bin/bash
set -e -x

apt-get update
apt-get upgrade -y
apt-get install -y git devscripts build-essential

{{ =include("../macosx-common.sh") }}
(
	tar -C /build/macos-rootfs -xvf /build/source/deps/libjpeg-turbo-*-osx64.tar.gz
	tar -C /build/macos-rootfs -xvf /build/source/deps/liblzma-*-osx64.tar.gz
) > /build/source/deps/filelist.txt

{{
	# FIXME: package_daily is ignored so far
	url = "http://download.osgeo.org/libtiff"
	download("libtiff.tar.gz", "%s/tiff-%s.tar.gz" % (url, package_version), sha)
}}

{{ for (host, arch) in [("i686-apple-darwin12", ""), ("x86_64-apple-darwin12", "64")] }}

su builder -c "mkdir build{{ =arch }}"
cd build{{ =arch }}
su builder -c "tar -xvf ../libtiff.tar.gz --strip-components 1"

su builder -c "./configure --prefix=/usr --host {{ =host }}"
cp config.log /build/config{{ =arch }}.log
su builder -c "make -j3"
su builder -c "mkdir /build/tmp{{ =arch }}"
su builder -c "make install DESTDIR=/build/tmp{{ =arch }}/"
# "make install" already copies license files to usr/share/doc/tiff-4.0.6
su builder -c "../fixup-import.py --destdir /build/tmp{{ =arch }} --filelist /build/source/deps/filelist.txt --verbose"

cd ..

{{ endfor }}

su builder -c "(cd /build/tmp; fakeroot tar -cvzf /build/{{ =output }}-osx.tar.gz .)"
su builder -c "./make-universal.py --dir32 /build/tmp --dir64 /build/tmp64"
su builder -c "(cd /build/tmp64; fakeroot tar -cvzf /build/{{ =output }}-osx64.tar.gz .)"
