from KivySwiftLink.build_files.pack_files import pack_all,remove_cache_file, create_package
from KivySwiftLink.pythoncall_builder import PythonCallBuilder
from KivySwiftLink.create_project import ProjectCreator
import sys
import os
import subprocess
import shutil
import json
from argparse import ArgumentParser
from os.path import dirname, abspath, join, exists,splitext

toolchain = "toolchain"

class BuildHandler:
    app_dir: str
    root_path: str

    def __init__(self, app_dir, root_path):
        self.app_dir = app_dir
        self.root_path = root_path


    def build_single(self, file: str):
        app_dir, root_path = self.app_dir, self.root_path

        name = file.split(".")[0]
        p_build = PythonCallBuilder(app_dir, root_path)

        p_build.build_py_files(
            join(root_path,"wrapper_sources",file) 
            )

        
        build = True
        if build:
            cmd = f"toolchain clean {name}"
            subprocess.run(cmd,  shell=True, stdout=None, stderr=None)


            cmd = f"toolchain build {name} --add-custom-recipe {join(root_path, 'wrapper_builds', name)}"
            subprocess.run(cmd, shell=True)

    

    def build_all(self, project_name: str ):
        app_dir, root_path = self.app_dir, self.root_path
        path = join(root_path,"wrapper_sources")
        names = []
        for root, dirs, files in os.walk(path):
            for file in files:
                if file != ".DS_Store":
                    print(file)
                    self.build_single(file)
                    names.append(splitext(file)[0])
        
        project = ProjectCreator(root_path, app_dir)
        project.project_target = join(root_path,f"{project_name}-ios")
        project.load_xcode_project()
        project.update_bridging_header(names)






    def install_extensions(self, extension:dict ):
        app_dir, root_path = self.app_dir, self.root_path
        project = ProjectCreator(root_path, app_dir)

        self._install_extensions(extension, project, root_path)

    def _install_extensions(self, extension:dict ,project: ProjectCreator, root_path: str):
        project_name = kw.get("project")
        project.project_target = join(root_path,f"{project_name}-ios")
        project.load_xcode_project()
        path = extension.get('path')
        group = extension.get('extension_name')

        project.add_swift_files(group,path)
        # for root, dirs, files in os.walk(path):
        #     for file in files:

                
        #         print(file)

    def create_project_with_extensions(self, extension:dict):
        app_dir, root_path = self.app_dir, self.root_path
        project = ProjectCreator(root_path, app_dir)

    def find_wrapper_files(self, path: str):
        py_files = []
        for root, dirs, files in os.walk(path):
            if root == path:
                for file in files:
                    _file_, ext = splitext(file)
                    if ext == '.py':
                        py_files.append(join(root,file))
        return py_files

if __name__ == '__main__':
    
    # p = ArgumentParser()
    # build_sub = p.add_subparsers()
    # #build_sub.add_argument("operation", help="./wrapper_tool_cli build <filename.py>")
    # #build_sub.add_argument("filename", help="wrapper_filename.py")
    # checkout = build_sub.add_parser('build', aliases=['-b'])
    # checkout.add_argument('filename')

    # args = p.parse_args()

    # t = args.operation

    # if t == "build":
    #     print("build is used")

    # elif t == "select-project":
    #     print("selecting project")

    args_size = len(sys.argv[1:])
    menu = """
    build       Build a wrapper file 
    create        Create a new xcode project
    """

    if args_size == 0:
        print(menu)
        exit(1)

    args = sys.argv[2:]
    t = sys.argv[1]
    #t = args[0]

    root_path = abspath(dirname(__file__))
    app_dir = join(root_path,"PythonSwiftLink")
    handler = BuildHandler(app_dir, root_path)
    if t == "build":
        if args_size -1 == 0:
            print("""build <wrapper_name.py>    -   build my_file.py 
        """)
            exit(1)
        _file_ = args[0]
        handler.build_single(
           _file_,
        )
        name = splitext(_file_)[0]
        project = ProjectCreator(root_path, app_dir)
        project.project_target = join(root_path,f"{args[1]}-ios")
        project.load_xcode_project()
        project.update_bridging_header([name])
        cmd = f"toolchain update {args[1]}-ios {name} --add-custom-recipe {join(root_path, 'wrapper_builds', name)}"
        subprocess.run(cmd, shell=True)
    
    elif t == "build_all":
        if args_size != 0:

            handler.build_all(args[0])


    elif t == "install_extension":
        
        _dir_ = args[1]
        print("Installing Extension",_dir_)
        with open(join(_dir_,"setup.json")) as f:
            kw = json.load(f)

        #py_files = find_wrapper_files(_dir_)
        py_files = [join(_dir_,wrap) for wrap in kw.get("wrappers")]
        #install_extensions(kw, app_dir, root_path)
        for file in py_files:
            shutil.copy(file, join(root_path, "wrapper_sources"))
            filebase = os.path.basename(file)
            handler.build_single(filebase)
        
        kw["project"] = args[0]
        kw["path"] = join(_dir_, "swift_sources")

        handler.install_extensions(kw)


    elif t == "create_pack":
        _file_ = args[1]
        _name_ = _file_.split(".")[0]
        p_build = PythonCallBuilder(app_dir, root_path)

    elif t == "create":
        project = ProjectCreator(root_path, app_dir)
        project.create_project(sys.argv[2], sys.argv[3])


    elif t == "create_with_extensions":
        kw = {

        }
        create_project_with_extensions()

    