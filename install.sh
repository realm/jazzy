/usr/bin/xcodebuild -workspace sourcekitten.xcworkspace -scheme sourcekitten CONFIGURATION_BUILD_DIR='${PWD}/build/' 
sudo cp ./build/sourcekitten /usr/local/bin/sourcekitten
