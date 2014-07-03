#!/bin/sh

# Generate temporary swift module map
header_file=$1
module_name='TempJazzyModule'
module_file='module.modulemap'
echo "module $module_name { header \"$header_file\" }" > $module_file

# Print generated Swift header
# See also -req=interface-gen
xcrun sourcekitd-test -req=doc-info -module $module_name -- -I `pwd` -sdk `xcrun --show-sdk-path`

# Remove temporary module file
rm $module_file
