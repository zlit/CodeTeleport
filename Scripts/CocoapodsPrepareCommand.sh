#!/bin/bash

# Add Build Phase 'CodeTeleport Script'
ruby -e 'require "rubygems"
require "xcodeproj"

script_phase_name = "CodeTeleport Script"

projects = Dir["*.xcodeproj"]
projects.each do|project|
    xcodeproj = Xcodeproj::Project.open("#{project}")
    xcodeproj.targets.each do |target|
        puts "- Intergate CodeTeleport for target '#{target}'"
        has_interated = false
        compile_source_phase_index = 0
        phase_index = 0
        script_phase = nil
        target.build_phases.each do |phase|
            if "#{phase}".include? "#{script_phase_name}"
                puts "* Already Intergated."
                script_phase = phase
                has_interated = true
            end

            if "#{phase}".include? "SourcesBuildPhase"
                compile_source_phase_index = phase_index 
            end

            phase_index = phase_index + 1
        end

        unless has_interated
            puts "* Add \"#{script_phase_name}\" Build Phase"
            script_phase = target.project.new(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
            target.build_phases.insert(compile_source_phase_index+1, script_phase)
        end

        script_phase.name = script_phase_name
        script_phase.shell_script = <<-EOS
        cd $PODS_ROOT/CodeTeleport
        app_path=$(find . -name 'CodeTeleport.app')

        if [ -z "$app_path" ]; then 
            echo "CodeTeleport.app not found" 
        else
            tmp_path="/tmp/com.zhaolei.CodeTeleport"
            if [ ! -d $tmp_path ] ; then
                mkdir $tmp_path
            fi

            echo save build enviroment to $tmp_path/build_enviroment.configs.

            printf "$SRCROOT\#$DEVELOPER_DIR\#$BUILD_DIR\#$DT_TOOLCHAIN_DIR\#$PLATFORM_DEVELOPER_SDK_DIR\#$TARGET_DEVICE_OS_VERSION\#$NATIVE_ARCH_ACTUAL\#$TARGET_DEVICE_IDENTIFIER" > $tmp_path/build_enviroment.configs

            echo "open $app_path"
            open $app_path
        fi
        EOS
        script_phase.show_env_vars_in_log = "0"
    end

    xcodeproj.save
end'
