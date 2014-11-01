#!/bin/sh

xcodebuild CONFIGURATION_BUILD_DIR='${PWD}/build/'
cp ./build/sourcekitten /usr/local/bin/sourcekitten
