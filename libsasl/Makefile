all: release

update: clean
	./prepare-cyrus-sasl.sh

clean:
	rm -rf ./build

release:
	# Building the XCFramework
	rm -rf ./build
	mkdir -p ./build
	
	-xcodebuild clean
	
	
	xcodebuild archive -project libsasl.xcodeproj -scheme libsasl -sdk iphoneos -archivePath "build/ios_devices.xcarchive" BUILD_LIBRARY_FOR_DISTRIBUTION=YES SKIP_INSTALL=NO OTHER_SWIFT_FLAGS=-no-verify-emitted-module-interface
	xcodebuild archive -project libsasl.xcodeproj -scheme libsasl -sdk iphonesimulator -archivePath "build/ios_simulators.xcarchive" BUILD_LIBRARY_FOR_DISTRIBUTION=YES SKIP_INSTALL=NO OTHER_SWIFT_FLAGS=-no-verify-emitted-module-interface
	xcodebuild archive -project libsasl.xcodeproj -sdk macosx MACOSX_DEPLOYMENT_TARGET=11.0 -arch arm64 BUILD_LIBRARY_FOR_DISTRIBUTION=YES -scheme libsasl -archivePath "build/macos_devices.xcarchive" SKIP_INSTALL=NO OTHER_SWIFT_FLAGS=-no-verify-emitted-module-interface
    
	xcodebuild -create-xcframework \
	  -framework build/ios_devices.xcarchive/Products/Library/Frameworks/libsasl.framework \
	  -framework build/ios_simulators.xcarchive/Products/Library/Frameworks/libsasl.framework \
	  -framework build/macos_devices.xcarchive/Products/Library/Frameworks/libsasl.framework \
	  -output build/libsasl.xcframework
    
	# Zip up libsasl.xcframework
	rm -f ../libsasl.xcframework.zip
	cd ./build && zip -X -y -r ../../libsasl.xcframework.zip libsasl.xcframework
	
	rm -rf ./build