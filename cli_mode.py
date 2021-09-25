from PythonSwiftLink.build_files.pack_files import pack_all,remove_cache_file, create_package
from PythonSwiftLink.pythoncall_builder import PythonCallBuilder
from PythonSwiftLink.create_project import ProjectCreator
import sys
import os
import subprocess

from os.path import dirname, abspath, join, exists

toolchain = "toolchain"


def build_single(file: str, app_dir: str, root_path: str):
    name = file.split(".")[0]
    p_build = PythonCallBuilder(app_dir, root_path)

    p_build.build_py_files(
        join(root_path,"wrapper_sources",file) 
        )

    create_package(
        root_path,
        app_dir,
        name
    )
    
    cmd = f"toolchain clean {name}"
    subprocess.run(cmd,  shell=True, stdout=None, stderr=None)


    cmd = f"toolchain build {name} --add-custom-recipe {join(root_path, 'wrapper_builds', name)}"
    subprocess.run(cmd, shell=True)


def build_all(app_dir:str ,root_path: str):
    path = join(root_path,"wrapper_sources")
    for root, dirs, files in os.walk(path):
        for file in files:
            build_single(file, app_dir, root_path)


if __name__ == '__main__':

    args = sys.argv[1:]
    t = args[0]

    root_path = abspath(dirname(__file__))
    app_dir = join(root_path,"PythonSwiftLink")

    if t == "build":
        _file_ = args[1]
        build_single(
           _file_,
           app_dir,
           root_path
       )
    
    elif t == "build_all":
        build_all(app_dir, root_path)




    elif t == "create_pack":
        _file_ = args[1]
        _name_ = _file_.split(".")[0]
        p_build = PythonCallBuilder(app_dir, root_path)

    elif t == "create":
        project = ProjectCreator(root_path, app_dir)
        project.create_project(sys.argv[2], sys.argv[3])

    #KivySwiftLink().run()