

## Creating a new project:


```sh
./wrapper_tool_cli create <project-name> <path-of-your-python-main.py-folder>
```
make a folder inside the working folder and call it py_src. u can call it whatever u feel like and place it anywhere you want, but for the sake of this tutorial we just use an internal folder as source.
```sh
./wrapper_tool_cli create kivytest_project ./py_src
```
Same thing as with kivy toolchain, only this runs on top of the toolchain and will do some extra things, to make the xcode project more suitable for running swift side by side with kivy.



## Writing first Python wrapper file:

next goto "wrapper_sources" and create a new python file.
in this case lets call it "kivytest.py"

and paste the following code:

```python
from swift_types import *

class KivyTest:

    # array/list of int
    @callback
    def get_swift_array(l: List[int]):
        pass

    @callback
    def get_swift_string(s: str):
        pass


    # array/list of int
    def send_python_list(l: List[int]):
        pass

    def send_python_string(s: str):
        pass
```

and run the following command:

```shell
./wrapper_tool_cli build <wrapper_file> <created-project-name>
```
```shell
./wrapper_tool_cli build kivytest.py kivytest_project
```
and open your xcode project.

## Xcode Project Setup

Now goto "sources" group and open "PythonMain.swift"

and add the folliwing 2 things to the class

```swift
var callback: KivyTestCallback?
```

```swift
InitKivyTestDelegate(self)
```



```swift
//PythonMain.swift
class PythonMain {
    
    var callback: KivyTestCallback?
  
    static let shared = PythonMain()
    
    private init() {
        InitKivyTestDelegate(self)
    }
}
```

```swift
extension PythonMain : KivyTestDelegate {
    
}
```

![protocol error](https://user-images.githubusercontent.com/2526171/112770707-41163c80-9028-11eb-9582-ca6666b7763b.png)

![protocol auto fix](https://user-images.githubusercontent.com/2526171/112770747-70c54480-9028-11eb-8fc4-08f825f49d25.png)

![protocol fixed](https://user-images.githubusercontent.com/2526171/112770891-39a36300-9029-11eb-8155-4850723c7422.png)

replace ```code``` in func ```set_KivyTest_Callback```
with the following:

```swift
self.callback = callback
```

replace ```code``` in func ```send_python_list```
with the following:

```swift
let array = pointer2array(data: l, count: l_size)
print("python list: ", array)

callback!.get_swift_array(array.reversed(), array.count)
```

replace ```code``` in func ```send_python_string```
with the following:

```swift
let string = s.asString()
print(string)

let swift_string = "Hallo from swift !!!!"
let c_string = swift_string.cString(using: .utf8)!
callback!.get_swift_string(c_string)
```



```swift
import Foundation

class PythonMain {
    
    var callback: KivyTestCallback?
    
    static let shared = PythonMain()
    
    private init() {
        InitKivyTestDelegate(self)
    }
}

extension PythonMain: KivyTestDelegate {
    func set_KivyTest_Callback(_ callback: KivyTestCallback) {
        self.callback = callback
    }
    
    func send_python_list(_ l: UnsafePointer<Int>, l_size: Int) {
        let array = pointer2array(data: l, count: l_size)
        print("python list: ", array)

        callback!.get_swift_array(array.reversed(), array.count)
    }
    
    func send_python_string(_ s: UnsafePointer<Int8>) {
        let string = s.asString()
        print(string)
        
        let swift_string = "Hallo from swift !!!!"
        let c_string = swift_string.cString(using: .utf8)!
        callback!.get_swift_string(c_string)
    }
    
    
}
```





### main.py

```python
#main.py
from typing import *

from kivytest import KivyTest


class KivyTestCallback:

    def get_swift_array(self, l: list):
        print("swift_array",list1)
        
    def get_swift_string(self, s: str):
        print(string)


callback = KivyTestCallback()

kivy_test = KivyTest(callback)

kivy_test.send_python_list([5,4,3,2,1])

kivy_test.send_python_string("Hallo from python and kivy")
```

![xcode running](https://user-images.githubusercontent.com/2526171/112787816-bc441680-9059-11eb-8572-c3b28d33b908.png)

Xcode console printed both the print statements from python and swift soo looks like the link is working xD


So this was ofcourse quite alot of steps to get to this simple printing script, 
so what about when updating python wrapper file with more send/callback functions.

Well this is why we needed the "Headers" group that always stays updated with the .h header file for your wrapper.

So if new @callback is created in your python wrapper file then xcode will automatic trigger the

```
Type 'Class' does not conform to protocol '<PythonClassName>Delegate'
Do you want to add protocol stubs?
```

So the process from here on, should be as simple as:

1. Update your Python Wrapper File
2. Run ./wrapper_tool_cli build <wrapper_file.py> <project-name>
3. If new Callbacks is created xcode will automatic notify you and add the stubs if you accept the prompt, and add your swift in the function code.
4. Hit run in xcode and see the new changes
   Simple as that. 
   Always remember to have the python virtual env active, while running the wrapper gui
   and general using the kivy-ios toolchain.

the kivy recipes doesnt rely on github uploads and uses fileurl to access the wrapper files directly from your harddrive
making process alot simpler when having to update minor/major changes to your wrapper library.

when returning to your project run the following:

```sh
cd <path of kivy-ios root project folder>
./wrapper_tool_cli <commands>
```

[Implementing a wrapper into a kivy app class](https://github.com/psychowasp/PythonSwiftLink/tree/main/examples/1%20Implementing%20a%20wrapper%20into%20a%20kivy%20app%20class)

### Arg Types:

| Python | Objective-C | Swift                |
| ------ | ----------- | -------------------- |
| bytes  | const char* | UnsafePointer\<Int8> |
| str    | const char* | UnsafePointer\<Int8> |
| int    | int         | Int32                |
| long   | long        | Int                  |
| float  | float       | Float                |
| double | double      | Double               |

### Special list types:

| Python       | Objective-C          | Swift                  |
| ------------ | -------------------- | ---------------------- |
| List[int]    | const int*           | UnsafePointer\<Int32\> |
| List[long]   | const long*          | UnsafePointer\<Int>    |
| List[uint]   | const unsigned int*  | UnsafePointer\<UInt32> |
| List[ulong]  | const unsigned long* | UnsafePointer\<UInt>   |
| List[float]  | const float*         | UnsafePointer\<Float>  |
| List[double] | const double*        | UnsafePointer\<Double> |

# [Implementing a wrapper into a kivy app class](https://github.com/psychowasp/PythonSwiftLink/tree/main/examples/1%20Implementing%20a%20wrapper%20into%20a%20kivy%20app%20class)