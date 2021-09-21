import sys
import os
import subprocess
import shutil
from os.path import dirname, abspath, join, exists
from pbxproj import XcodeProject,PBXKey
from pbxproj.pbxextensions.ProjectFiles import FileOptions

toolchain = "toolchain"

class ProjectCreator:

    def __init__(self, root_path, app_dir):
        self.app_dir = app_dir
        self.root_path = root_path
        self.project_target = root_path

    def create_project(self,title,path):
        command = " ".join([toolchain, "create", title, path])  # the shell command
        # self.execute(command,0,False)
        subprocess.run(command, shell=True)
        self.project_target = join(self.root_path,f"{title}-ios")
        self.update_classes_group()

    def load_xcode_project(self):
        if self.project_target:
            try:
                target = self.project_target
                target_name = os.path.basename(target)[:-4]
                print("target_name: ",target_name)
                path = "%s/%s.xcodeproj/project.pbxproj" % (target, target_name)
                self.project = XcodeProject.load(path)
            # for 
            except:
                print("project failed invalid path:", str(self.project_target))
                return

    def update_classes_group(self):
        self.load_xcode_project()
        project = self.project
        project_updated = True
        
        if not project:
            return
        if self.project_target and self.project:
            project.remove_framework_search_paths(["/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator14.4.sdk/System/Library/Frameworks"])
            project.remove_library_search_paths(["/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator14.4.sdk/usr/lib"])
            target = self.project_target
            target_name = os.path.basename(target)[:-4]
            print("target_name: ",target_name)
            path = "%s/%s.xcodeproj/project.pbxproj" % (target, target_name)
            # project = XcodeProject.load(path)
            project = self.project
            sources = project.get_or_create_group("Sources")
            sources_list = set([child._get_comment() for child in sources.children])
            
            for src in sources.children:
                ID = str(src)
                file = src._get_comment()
                if file in ["main.m"]:
                    project.remove_file_by_id(ID)
            try:
                project.remove_group_by_name("Classes")
            except:
                print("removing classes failed")
            classes = project.get_or_create_group("Classes")
            classes_list = set([child._get_comment() for child in classes.children])
            with open(join(self.app_dir,"project_build_files","runMain.m"), "r") as f:
                main_string = f.read()
            with open(join(self.project_target,"runMain.m"), "w") as f:
                f.write(main_string.replace("{$project_path}",self.root_path))
            if not exists(join(self.project_target,"runMain.h")):
                shutil.copy(join(self.app_dir,"project_build_files","runMain.h"), join(self.project_target,"runMain.h"))
            for item in ("runMain.h","runMain.m"):
                if item not in classes_list and item != ".DS_Store":
                    project.add_file(join(self.project_target,item), parent=classes)
                    project_updated = True

                        
            for (dirpath, dirnames, filenames) in os.walk(join(self.app_dir, "project_build_files")):
                for item in filenames:
                    if item not in sources_list and item != ".DS_Store" and item.lower().endswith(".swift"):
                        dst = join(self.project_target,item)
                        shutil.copy(join(dirpath,item),dst)
                        #print(dirpath,item)
                        project.add_file(dst, parent=sources)
                        project_updated = True
            pro_file = ""
            with open(path, "r") as f:
                pro_file = f.read()
            update_bridge = False
            bridge_header = join(self.project_target,f"{target_name}-Bridging-Header.h")
            if not exists(bridge_header):
                bridge_strings = [
                    "\n#import \"runMain.h\"",
                    "\n\n",
                    "//#Wrappers Start",
                    "//  Insert Your Wrapper Headers Here -> #import \"wrapper_class_name\".h//  ",
                    "\n",
                    "//#Wrappers End",
                    "\n\n",
                    "//Insert Other OBJ-C Headers Here:"

                ] 
                with open(bridge_header, "w") as b:
                    b.write("\n".join(bridge_strings))
            project.set_flags("SWIFT_OBJC_BRIDGING_HEADER",f"{target_name}-Bridging-Header.h")
            project.set_flags("SWIFT_VERSION","5.0")
            project.set_flags("IPHONEOS_DEPLOYMENT_TARGET","11.0")


            project.add_file(bridge_header, parent=classes, force=False)

            project.add_header_search_paths(join(self.root_path,"wrapper_headers"),False)

            if project_updated:
                project.backup()
                project.save()