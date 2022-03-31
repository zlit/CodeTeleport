# Add Build Phase 'CodeTeleport Script'
require "xcodeproj"


tmp_path='/tmp/com.zhaolei.CodeTeleport'
if File.directory?(tmp_path)
    delete_command = 'rm -rf ' + tmp_path
    puts delete_command
    system(delete_command)
end

target_name = 'HHOPortal'
if ARGV.length > 0
    target_name = ARGV[0]
end

puts 'Add Build Phase Target : ' + target_name

script_phase_name = "CodeTeleport Script"

projects = Dir["*.xcodeproj"]
projects.each do|project|
    xcodeproj = Xcodeproj::Project.open("#{project}")
    xcodeproj.targets.each do |target|

        if target.name != target_name
            next
        end

        puts "- Intergate CodeTeleport for target '#{target}'"
        has_interated = false
        phase_index = 0
        script_phase = nil
        target.build_phases.each do |phase|
            if "#{phase}".include? "#{script_phase_name}"
                puts "* Already Intergated."
                script_phase = phase
                has_interated = true
            end
            phase_index = phase_index + 1
        end

        unless has_interated
            puts "* Add \"#{script_phase_name}\" Build Phase"
            script_phase = target.project.new(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
            target.build_phases.insert(phase_index, script_phase)
        end

        script_phase.name = script_phase_name
        script_phase.shell_script = <<-EOS
if [[ $CONFIGURATION == "Debug" ]]; then

echo CONFIGURATION:$CONFIGURATION

tmp_path=/tmp/com.zhaolei.CodeTeleport
assets_path=$tmp_path/CodeTeleport
ct_client_dylib_name=CTClient
ct_client_dylib_path=$assets_path/$ct_client_dylib_name.framework/$ct_client_dylib_name
ct_app_path=$assets_path/CodeTeleport.app
optool_path=$assets_path/optool

if [ ! -d $tmp_path ]; then
    mkdir $tmp_path
fi

#1.find local_pod_project_paths
local_pod_project_paths=""
array=($FRAMEWORK_SEARCH_PATHS)
for LIBRARY_PATH in ${array[@]}
do
    stripped_library_path=$(echo "$LIBRARY_PATH" | tr -d "\\\"")
    for folder in `ls -1 $SRCROOT/../`
    do
        if [[ -d $SRCROOT/../$foler ]]; then
            for secondary_folder in `ls -1 $SRCROOT/../$folder`
            do
                if [[ $secondary_folder == *"xcodeproj" ]]; then
                    if [[ $stripped_library_path == *"${secondary_folder%.*}" ]]; then
                        local_pod_project_paths="$SRCROOT/../$folder,$local_pod_project_paths"
                        break
                    fi
                fi
            done
        fi
    done
done

echo "local_pod_project_paths : $local_pod_project_paths"

#2.save env vars

echo '$SRCROOT : ' $SRCROOT
echo '$DEVELOPER_DIR : ' $DEVELOPER_DIR
echo '$BUILD_DIR : ' $BUILD_DIR 
echo '$DT_TOOLCHAIN_DIR : ' $DT_TOOLCHAIN_DIR
echo '$SDKROOT : ' $SDKROOT
echo '$TARGET_DEVICE_OS_VERSION : ' $TARGET_DEVICE_OS_VERSION
echo '$EXPANDED_CODE_SIGN_IDENTITY : ' $EXPANDED_CODE_SIGN_IDENTITY
echo '$CODESIGNING_FOLDER_PATH : ' $CODESIGNING_FOLDER_PATH
echo '$FRAMEWORKS_FOLDER_PATH : ' $FRAMEWORKS_FOLDER_PATH
echo '$EXECUTABLE_PATH : ' $EXECUTABLE_PATH
echo '$PRODUCT_NAME : ' $PRODUCT_NAME

printf "$SRCROOT\#$DEVELOPER_DIR\#$BUILD_DIR\#$DT_TOOLCHAIN_DIR\#$SDKROOT\#$TARGET_DEVICE_OS_VERSION\#$ARCHS\#$TARGET_DEVICE_IDENTIFIER\#$EXPANDED_CODE_SIGN_IDENTITY\#$CODESIGNING_FOLDER_PATH\#$FRAMEWORKS_FOLDER_PATH\#$EXECUTABLE_PATH\#$PRODUCT_NAME\#$local_pod_project_paths" > $tmp_path/build_enviroment.configs

#3.download assets

is_first_install="false"
if [ ! -d $assets_path ]; then
    curl https://hhocool-app-persistent-log.oss-ap-southeast-1.aliyuncs.com/CodeTeleport.zip >> $tmp_path/CodeTeleport.zip
    mkdir $assets_path
    unzip $tmp_path/CodeTeleport.zip -d $assets_path
    is_first_install="true"
fi

#4.install clientDylib

TARGET_APP_PATH=$BUILT_PRODUCTS_DIR/$TARGET_NAME.app 
EXECUTABLE_PATH=$BUILT_PRODUCTS_DIR/$EXECUTABLE_PATH

if [ ! -d $TARGET_APP_PATH/CodeTeleport ]; then 
    echo "mkdir $TARGET_APP_PATH/CodeTeleport" 
    mkdir $TARGET_APP_PATH/CodeTeleport
fi

cp -rf $ct_client_dylib_path $TARGET_APP_PATH/CodeTeleport

if [[ $PLATFORM_NAME != "iphonesimulator" ]]; then
    echo "Code Signing $TARGET_APP_PATH/CodeTeleport/$ct_client_dylib_name"
    /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$TARGET_APP_PATH/CodeTeleport/$ct_client_dylib_name"
fi

$optool_path install -c load -p "@executable_path/CodeTeleport/$ct_client_dylib_name" -t "$EXECUTABLE_PATH"

#5. open app

pid=$(ps -ef |grep CodeTeleport|grep -v "grep"|cut -c 7-12)
echo $pid
if [ ! -z "$pid" ]; then
    echo "kill CodeTeleport.app"
    echo $pid | xargs kill -9
    sleep 0.2
fi

#https://stackoverflow.com/questions/2182040/the-application-cannot-be-opened-because-its-executable-is-missing
if [[ $is_first_install == "true" ]]; then
    echo "force register $ct_app_path"
    /System/Library/Frameworks/Coreservices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f $ct_app_path
fi

echo "open $ct_app_path"
open $ct_app_path
fi
        EOS
        script_phase.show_env_vars_in_log = "0"
    end

    xcodeproj.save
end
