# PythonSwiftLink

 ## Installation

Make sure you have **Python 3.9.2** installed since this tool only tagets python3.8 internal and kivy-ios runs on 3.9.2

so i recommend having the working python version in sync with the kivy-ios

https://www.python.org/ftp/python/3.9.2/python-3.9.2-macosx10.9.pkg

after installation make sure to run 

/Applications/Python 3.9/Install Certificates.command

else kivy-ios cant build anything.

Like normal kivy-ios make sure to do the **Prerequisites** part of the standard kivy-ios [tutorial](https://kivy.org/doc/stable/guide/packaging-ios.html)  

Open Terminal

and goto to the root of where you want your new kivy build folder


```sh
cd path-of-the-root
```

copy / paste the following line:

 ```sh
sh -c "$(curl -sSL https://raw.githubusercontent.com/psychowasp/KivySwiftLink/main/KivySwiftLink-Install.sh)"
 ```
You should now be prompted with the following:

 ```sh
 Options:
#############################################
w   -   create working folder and run setup
x   -   exit
#############################################
 ```
Type **w** and hit enter to create a new build folder
and you will be followed up by the question of what to name your build folder:

 ```sh
type folder name - default is:

  kivyswift
 ```
For the sake of the tutorial just hit **Enter** and it will use the default name **kivyswift**

Now the script will do the following for you

1. Creates a new dir with your selected name **kivyswift** in this example
2. create a new **virtual environment** called **venv** inside the working folder 
3. Installs all the necessary python librarys inside the new **venv**: 

   - normal **Kivy** for the gui part
   - **Cython** and **Kivy-ios** for the toolchain
   - **Watchdog** to observe wrapper file changes while the GUI App is running(more about that later)
   - **TinyDB** to keep track of projects and compiled wrapper builds and build dates (not fully working yet) 
4. Copy the python gui app file to the root of your new build folder
5. Copy a SH file and makes it executable, since this is the file the "Wrapper Tool" will be executed with.
6. Now the script will run kivy toolchain and build python/kivy.
7. Like the official kivy-ios statement says: **Don't grab a coffee, just do diner.** Compiling all the libraries for the first time, 2x over (remember, 2 archs, x86_64, arm64) will take time.
8. ..................... and now script should be done...



now goto the new build folder **kivyswift**(in this tutorial)

```sh
cd kivyswift
```

### [Create a new project](https://github.com/psychowasp/KivySwiftLink/tree/main/examples/0%20Getting%20Started ) 

