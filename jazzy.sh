#!/bin/sh

jazzy -m SourceKitten \
-a "JP Simard" \
-u https://github.com/jpsim/SourceKitten \
-g https://github.com/jpsim/SourceKitten \
--github-file-prefix https://github.com/jpsim/SourceKitten/blob/0.6.0 \
--module-version 0.6.0 \
-r http://www.jpsim.com/SourceKitten/ \
-x -workspace,SourceKitten.xcworkspace,-scheme,SourceKittenFramework \
-c
