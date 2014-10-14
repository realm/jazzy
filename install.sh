/usr/bin/xcodebuild -configuration Debug -workspace SourceKitten.xcworkspace -scheme SourceKitten CONFIGURATION_BUILD_DIR='${PWD}/build/' 
sudo cp ./build/SourceKitten /usr/local/bin/SourceKitten