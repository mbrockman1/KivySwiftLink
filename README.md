# KivySwiftLink
What is KivySwiftLink ?


## -- Installation --

Download a release.
Open a terminal and goto the folder you downloaded KivySwiftLink to.

Then run:
```sh
./KivySwiftLink install
```
it will ask you if you want to copy the file as **ksl** to **/usr/local/bin/**

so from now on you just have to run KivySwiftLink like this:
```sh
ksl <commands>
```
same install command is used when downloading newer releases and updating it.





## -- Setup a working folder --

Make sure you have **Python 3.9.2** installed since this tool only works with a python3.9 installed 
kivy-ios runs on 3.9.2, so i recommend having the working python version in sync with the kivy-ios


https://www.python.org/ftp/python/3.9.2/python-3.9.2-macosx10.9.pkg

after installation make sure to run 

/Applications/Python 3.9/Install Certificates.command

else kivy-ios cant build anything, also KivySwiftLink wont run the setup process, without being able to detect a python 3.9.
Else it will ask you to download the same Python from the link above.

Like normal kivy-ios make sure to do the **Prerequisites** part of the standard kivy-ios [tutorial](https://kivy.org/doc/stable/guide/packaging-ios.html)  

Open Terminal

and goto to the root of where you want your new kivy build folder


```sh
cd path-of-the-root
```

 ```sh
ksl setup
 ```

and it will do the following for you

1. create a new **virtual environment** called **venv** inside the working folder 
2. Installs all the necessary python librarys inside the new **venv**: 
   - **Cython** and **Kivy-ios** for the toolchain

3. Now the script will run kivy toolchain and build python/kivy.
4. Like the official kivy-ios statement says: **Don't grab a coffee, just do diner.** Compiling all the libraries for the first time, 2x over (remember, 2 archs, x86_64, arm64) will take time.
5. ..................... and now script should be done...

### [Create a new project](https://github.com/psychowasp/KivySwiftLink/tree/main/examples/0%20Getting%20Started ) 

