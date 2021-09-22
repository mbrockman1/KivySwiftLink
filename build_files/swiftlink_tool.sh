#!/bin/sh
# Ask the user for login details
BASEDIR=$(dirname $0)
INPUT_STRING=none
folder_var=kivyswift
# while [ "$INPUT_STRING" != "x" ]
# do
echo $BASEDIR
echo """
Options:
#############################################
w   -   create working folder and run setup
x   -   exit
#############################################
"""

read -p "command: " INPUT
INPUT_STRING=$INPUT

if [ "$INPUT_STRING" = "r" ]; then
    echo ""
elif [ "$INPUT_STRING" = "w" ]; then
    echo "type folder name - default is:"
    echo
    echo "  kivyswift"
    echo
    read -p 'Folder name: ' folder_var
    if [ $folder_var = ""]
    then
        folder_var=kivyswift
    fi


    echo
    echo Creating Dir $folder_var
    mkdir ./$folder_var
    cd $folder_var
    echo $(dirname $0)

    python3.8 -m venv venv
    . venv/bin/activate
        pip install cython
    pip install kivy
    pip install kivy-ios
    pip install astor
    pip install tinydb
    pip install applescript
    pip install watchdog

    #        rsync -av --delete --exclude '.git' /Users/macdaw/kivyios_swift/PythonSwiftLink/* ./PythonSwiftLink
    git clone https://github.com/psychowasp/PythonSwiftLink
    cp ./PythonSwiftLink/main.py ./wrapper_tool.py
    cp ./PythonSwiftLink/wrapper_tool.sh ./wrapper_tool
    
    cp ./PythonSwiftLink/cli_mode.py ./
    
    cp ./PythonSwiftLink/wrapper_tool_cli.sh ./wrapper_tool_cli
    chmod +x wrapper_tool_cli

    cp ./PythonSwiftLink/build_files/swift_types.py ./venv/lib/python3.8/site-packages/
    cp ./PythonSwiftLink/build_files/free_type_fix.py ./venv/lib/python3.8/site-packages/kivy_ios/recipes/freetype/__init__.py
    chmod +x wrapper_tool
    
    toolchain build kivy
    mkdir wrapper_sources
    mkdir wrapper_builds
    mkdir wrapper_headers
    
    echo
    echo "Working folder <$folder_var> is now ready"
    echo
    cd $BASEDIR
    
    echo "$BASEDIR"
    # read -p 'Project name: ' pro_var

    #toolchain create $pro_var
else
     echo "not supported"
fi;
