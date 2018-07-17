#!/bin/sh

CTClientPath="/Users/zhaolei/Library/Developer/Xcode/DerivedData/CodeTeleportClient-akavrjbpnqjaxqaqxnpkoloawdyo/Build/Products/Release-iphonesimulator/CTClient.framework"
CTServerPath="/Users/zhaolei/Library/Developer/Xcode/DerivedData/CodeTeleport-evsrcdavqhsamqcgolxuvfmkxaay/Build/Products/Release/CodeTeleport.app"

if [ ! -d $CTClientPath ]; then
	echo 'CTClientPath不存在'
	exit 0
fi

if [ ! -d $CTServerPath ]; then
	echo 'CTServerPath不存在'
	exit 0
fi

work_path=$(cd $(dirname ${BASH_SOURCE:-$0});pwd)
targetCTClientPath="$work_path/CTClient.framework"
targetCTServerPath="$work_path/CodeTeleport.app"

rm -r -f -d $targetCTClientPath
rm -r -f -d $targetCTServerPath

cp -a $CTClientPath $targetCTClientPath
cp -a  $CTServerPath $targetCTServerPath

if [ ! -d $CTClientPath ]; then
	echo 'move targetCTClientPath failed'
	exit 0
fi

if [ ! -d $CTServerPath ]; then
	echo 'move targetCTClientPath failed'
	exit 0
fi
exit 1
