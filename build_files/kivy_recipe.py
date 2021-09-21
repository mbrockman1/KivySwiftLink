from kivy_ios.toolchain import CythonRecipe, shprint
from os.path import join
from distutils.dir_util import copy_tree
#from .module_name import *
from os.path import join,dirname,exists
import fnmatch
import sh
import os
import urllib.parse
import json

#test
module_name = "MODULE_NAME"
custom_root = "CUSTOM_ROOT"
module_folder = "MODULE_FOLDER"
py_version = "PY_VERSION"
osx_version = "OSX_VERSION"

class RECIPENAME_Recipe(CythonRecipe):
    version = "master"
    custom_dir = join("./","wrapper_builds",module_name,"src")
    #url = 'file:./' + urllib.parse.quote(join("wrapper_builds",module_name,"master.zip"))
    library = f"lib{module_name.lower()}.a"
    depends = ["python3", "hostpython3"]
    pre_build_ext = True
    archs = ['x86_64','arm64','arm64e','armv7','armv7s']

    def install(self):
        arch = list(self.filtered_archs)[0]
        build_dir = join(self.get_build_dir(arch.arch), 'build', f'lib.macosx-{osx_version}-x86_64-{py_version}')
        with open(join(build_dir, '__init__.py'), 'wb'):
            pass
        
        build_path = ['root', 'python3', 'lib', 'python3.8', 'site-packages']
        if custom_root:
            with open(join(build_dir,custom_root ,'__init__.py'), 'w'):
                pass
            build_path.append(custom_root)
        if module_folder:
            if custom_root:
                path = join(build_dir,custom_root ,module_folder,'__init__.py')
            else:
                path = join(build_dir ,module_folder,'__init__.py')
            with open(path, 'w'):
                pass
            build_path.append(module_name)

        dist_dir  = join(self.ctx.dist_dir, *build_path)
        copy_tree(build_dir, dist_dir)

    # def biglink(self):
    #     dirs = []
    #     for root, dirnames, filenames in os.walk(self.build_dir):
    #         if fnmatch.filter(filenames, "*.so.*"):
    #             dirs.append(root)
    #         if fnmatch.filter(filenames, "*.o.*"):
    #             dirs.append(root)
    #     cmd = sh.Command(join(self.ctx.root_dir, "tools", "biglink"))
    #     shprint(cmd, join(self.build_dir, f"lib{module_name.lower()}.a"), *dirs)

recipe = RECIPENAME_Recipe()
