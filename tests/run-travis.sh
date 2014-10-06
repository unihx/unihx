#!/bin/bash
ORIGINAL=$PWD
source ~/travis-hx/defaults.sh

case ${DEVICE} in
	desktop )
		cd ~
		# download mac unity example app executable
		retry curl -L "https://docs.google.com/uc?export=download&id=0B8FjDKR0nfqoQmpOYW44S2c3SU0" -o mac.tar.gz || exit 1
		tar -zxf mac.tar.gz || exit 1
		chmod +x test.app/Contents/MacOS/test

		cd $ORIGINAL
		# command-line test
		haxe build.hxml || exit 1
		mono --debug bin/bin/CmdTests-Debug.exe || exit 1

		# unity example app test
		haxe build-unity.hxml || exit 1
		cp bin/bin/bin-Debug.dll ~/test.app/Contents/Data/Managed

		cd ~
		./test.app/Contents/MacOS/test || exit 1
		cat /tmp/unity_test_result.txt || exit 1

		# will fail if .noErrors file is not created
		cat /tmp/.unity_no_errors || exit 1
		;;
	ios )
		cd ~
		# download example ios app project
		retry curl -L "http://waneck-pub.s3-website-us-east-1.amazonaws.com/unitdeps/unity/proj-1.tgz" -o proj-1.tgz > /dev/null || exit 1
		tar -zxf proj-1.tgz || exit 1
		# download ios tools
		retry curl -L "https://docs.google.com/uc?export=download&id=0B8FjDKR0nfqoU1p1dktXanI4M3c" -o iostools.tgz > /dev/null || exit 1
		tar -zxf iostools.tgz || exit 1
		chmod +x iostools/ldid
		chmod +x iostools/Tools/OSX/mono-xcompiler

		# build ios-runner
		cd $ORIGINAL/ios-runner
		echo "Client build"
		haxe build-client.hxml || exit 1
		cp bin/client.n ~/ios-remote.n

		cd $ORIGINAL
		echo "Unity DLL build"
		# build as we would for unity example app
		haxe build-unity.hxml || exit 1

		# replace the .dll
		cp bin/bin/bin-Debug.dll ~/proj-1/Data/Managed/ || exit 1

		# setup mono-xcompiler
		export MONO_PATH=${HOME}/proj-1/Data/Managed
		export GAC_PATH=${HOME}/proj-1/Data/Managed
		# xcompile
		cd ~/proj-1/Data/Managed
		for file in *.dll; do
			echo "AOT compiling $file"
			~/iostools/Tools/OSX/mono-xcompiler --aot=full,asmonly,nodebug,static,outfile=$file.s $file > /tmp/mono-out.out || (cat /tmp/mono-out; exit 1)
		done
		mv *.s ../../Libraries || exit 1

		# build using xcode but do not sign
		cd ../../
		echo "XCode compiling"
		xcodebuild -alltargets -configuration Debug clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO > /tmp/xcode-out.out || (cat /tmp/xcode-out.out; exit 1)
		# fake sign
		~/iostools/ldid -S build/ProductName.app/ProductName || exit 1

		# max compression
		export GZIP=-9
		cd build
		tar -zcf ios-app.tar.gz ProductName.app

		echo "Remote iOs test"
		neko ~/ios-remote.n --retries 5 -s "$IOS_REMOTE_SHARED" -c "$ORIGINAL/config.json" -f 'ios-app.tar.gz' --connect $IOS_REMOTE_ARGS || exit 1
		;;
esac
