# Creating a new project:

after running ./wrapper_tool.sh

you should be presented with the following screen:

![Screenshot 2021-04-19 at 17.48.23](https://raw.githubusercontent.com/psychowasp/PythonSwiftLink/testing/examples/0%20Getting%20Started/images/Screenshot%202021-04-19%20at%2017.48.23.png)





# Writing first Python wrapper file:



## Wrapper file

    Pick your Class Name vicely..
    it will be the main name type for the generated files and Protocol/Struct name

in \<project-folder\>/wrapper_sources/ 

create a new file called "kivytest.py"
insert the following code

 ### Code: 

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

### Launch the wrapper gui

From the root folder "kivyswift/"
run:

```sh
python3 main.py

```

## Xcode Project Setup



Now lets finally add some swift code:

```swift
//PythonMain.swift
class PythonMain : NSObject {
    
    var callback: KivyTestCallback?
    
    static let shared = PythonMain()
    
    private override init() {
        super.init()
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
let string = String.init(cString: s)
print(string)

let swift_string = "Hallo from swift !!!!"
callback!.get_swift_string(swift_string)
```

![function missing](https://user-images.githubusercontent.com/2526171/112969631-b891bc00-914d-11eb-8788-4e262f0c1a9c.png)

of course we got no function yet called "pointer2array" to convert a c pointer to an array.
so lets add that:

![Final Extension](https://user-images.githubusercontent.com/2526171/112967256-60f25100-914b-11eb-8fb6-d5d0a395f5df.png)

```swift
// this function is using generic type, so it should cover most of the pointer array types from c/python
func pointer2array<T>(data: UnsafePointer<T>,count: Int) -> [T] {

    let buffer = UnsafeBufferPointer(start: data, count: count);
    return Array<T>(buffer)
}
```

Now the only thing left on the swift side is too add this piece of code, at the bottom of the PythonMain.swift file.

```swift
var pythonMain: PythonMain?

@_cdecl("SDL_main")
func main(_ argc: Int32, _ argv: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>) -> Int {
    pythonMain = PythonMain.shared
    run_main(argc, argv)
    //run_python(argc: Int(argc), argv: argv)
    
    return 1
}
```

This will replace the main.m function that normaly is triggered by SDL when app is launching. 
why we needed to add that runMain.h and .m (copy of the main.m) so we can execute it as a normal function.

the swift version of main will first init the "PythonMain" by using the shared and assign it to a global pythonMain var.
this will be the global default class that will handle all future swift classes that needs to be wrapped. 

![run main class](https://user-images.githubusercontent.com/2526171/112968795-ed514380-914c-11eb-8291-0e2afe5e7971.png)

# Python File

### main.py

```python
#main.py

from kivytest import KivyTest


class KivyTestCallback:

    def get_swift_array(self, l: [int]):
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
2. Run the "build selected" and "compile selected" in the WrapperGUI on your .py file
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
./wrapper_tool.sh
```

[Implementing a wrapper into a kivy app class](https://github.com/psychowasp/PythonSwiftLink/tree/main/examples/1%20Implementing%20a%20wrapper%20into%20a%20kivy%20app%20class)

### Arg Types:

| Python | Objective-C | Swift                       |
| ------ | ----------- | --------------------------- |
| bytes  | const char* | UnsafePointer\<Int8> |
| str    | const char* | UnsafePointer\<Int8> |
| int    | int         | Int32                       |
| long   | long        | Int                         |
| float  | float       | Float                       |
| double | double      | Double                      |

### Special list types:

| Python       | Objective-C          | Swift                         |
| ------------ | -------------------- | ----------------------------- |
| List[int]    | const int*           | UnsafePointer\<Int32\> |
| List[long]   | const long*          | UnsafePointer\<Int>    |
| List[uint]   | const unsigned int*  | UnsafePointer\<UInt32> |
| List[ulong]  | const unsigned long* | UnsafePointer\<UInt>   |
| List[float]  | const float*         | UnsafePointer\<Float>  |
| List[double] | const double*        | UnsafePointer\<Double> |

# [Implementing a wrapper into a kivy app class](https://github.com/psychowasp/PythonSwiftLink/tree/main/examples/1%20Implementing%20a%20wrapper%20into%20a%20kivy%20app%20class)
