#!/bin/sh

basepath=$(cd `dirname $0`; pwd)
# echo $basepath
rm -rf $basepath/Product
mkdir $basepath/Product
xcodebuild -target CTClient -configuration Release
xcodebuild -target CTClient -configuration Release -sdk iphonesimulator
lipo -create $basepath/build/Release-iphonesimulator/CTClient.framework/CTClient $basepath/build/Release-iphoneos/CTClient.framework/CTClient -output $basepath/Product/CTClient
mv -f $basepath/build/Release-iphoneos/CTClient.framework $basepath/Product/CTClient.framework
mv -f $basepath/Product/CTClient $basepath/Product/CTClient.framework/CTClient
rm -rf $basepath/Product/CTClient
rm -rf $basepath/build



