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
    
    git clone https://github.com/psychowasp/KivySwiftLink
    
    python3.8 -m venv venv
    . venv/bin/activate
    pip install cython
    pip install kivy
    #pip install kivy-ios
    pip install git+https://github.com/meow464/kivy-ios.git@custom_recipes
    pip install astor
    pip install tinydb
    pip install applescript
    pip install watchdog
    
    pip install ./KivySwiftLink

    #        rsync -av --delete --exclude '.git' /Users/macdaw/kivyios_swift/PythonSwiftLink/* ./PythonSwiftLink
    
    #cp ./KivySwiftLink/main.py ./wrapper_tool.py
    #cp ./KivySwiftLink/wrapper_tool.sh ./wrapper_tool
    
    #cp ./PythonSwiftLink/cli_mode.py ./
    
    cp ./KivySwiftLink/wrapper_tool_cli.sh ./wrapper_tool
    chmod +x wrapper_tool

    cp ./KivySwiftLink/src/swift_types.py ./venv/lib/python3.8/site-packages/
    rm -R -f KivySwiftLink
    #chmod +x wrapper_tool
    
    mkdir wrapper_sources
    mkdir wrapper_builds
    mkdir wrapper_headers
    toolchain build kivy

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
