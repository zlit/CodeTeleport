#1.find local_pod_project_paths
local_pod_project_paths=""
array=($LIBRARY_SEARCH_PATHS)
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