import json
from typing import List
from camera_view import CameraView
from camera_api import CameraApi
from kivy.app import App
from kivy.clock import mainthread
from kivy.graphics.texture import Texture
from kivy.lang import Builder
from kivy.properties import (BooleanProperty, ListProperty, NumericProperty,
                             ObjectProperty, StringProperty, AliasProperty)
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.dropdown import DropDown
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.gridlayout import GridLayout
from kivy.uix.label import Label
from kivy.uix.relativelayout import RelativeLayout
from kivy.uix.widget import Widget
from kivy.metrics import dp
from kivy.uix.image import Image

from kivy.uix.popup import Popup

class OSD_Icon(Label):
    state = BooleanProperty(False)
    
    def on_touch_down(self,touch):
        if self.collide_point(*touch.pos):
            self.state = not self.state
            return True
    

class MainView(BoxLayout): ...

class PreviewPresets(GridLayout): ...

class CaptureIcon(Image):
    app = ObjectProperty(None)
    def on_touch_down(self,touch):
        if self.collide_point(*touch.pos):
            self.color = [1,0,0,1]
            return True
    
    def on_touch_up(self,touch):
        if self.collide_point(*touch.pos):
            self.color = [1,1,0,1]
            self.app.camera_api.take_photo()
            return True
        
        
class CapturePopup(Popup):
    img = ObjectProperty(None)
    
    def __init__(self, **kwargs):
        super(CapturePopup, self).__init__(**kwargs)
    
    
    def show_capture(self, buffer: bytes, width, height):
        tex: Texture = Texture.create(
            size=(width, height),
            colorfmt="bgra",
            bufferfmt="ubyte"
            )
        tex.blit_buffer(buffer, colorfmt="bgra")
        tex.flip_vertical()
        self.img.texture = tex
        self.open()

class OSD_DropIcon(OSD_Icon):
    icons = ListProperty(None)
    selected = StringProperty(None)
    
    def __init__(self, **kwargs):
        super(OSD_DropIcon,self).__init__(**kwargs)
        
        self.dropdown = DropDown(auto_width=False, size_hint_x=0.3)
        self.dropdown.bind(on_select=self.setter("selected"))
    
    def on_selected(self,*args):
        print(args)
    
    def open_dropdown(self):
        self.dropdown.open(self)    
    
    def on_icons(self, wid, icons):
        dropdown = self.dropdown
        dropdown.clear_widgets()
        for i, icon in enumerate(icons):
            btn = Button(text=icon, size_hint_y=None, height=dp(44))
            btn.index = i
            btn.bind(on_release=lambda btn: dropdown.select(btn.text))
            dropdown.add_widget(btn)
            
    def on_touch_down(self,touch):
        if self.collide_point(*touch.pos):
            # self.state = not self.state
            self.open_dropdown()
            return True
        
    # def on_state(self,wid,state):
    #     if state:
    #         self.open_dropdown()

class MyCameraView(CameraView):
    

    def on_touch_down(self, touch):
        if self.collide_point(*touch.pos):
            _x,_y = touch.pos
            for child in self.children:
                if child.collide_point(_x, _y):
                    child.on_touch_down(touch)
                    return True
            x = _x - self.x
            y = _y - self.y
            self.touch_pos = [_x, _y]
            self.touched = 1
            self.set_focus_point(self.app, x, y)
            
            #return super().on_touch_down(touch)
    
    def on_touch_up(self, touch):
        if self.collide_point(*touch.pos):
            self.touched = 0
            return super().on_touch_up(touch)

    def set_focus_point(self, app, x , y):
        focus_x =  x / self.width 
        focus_y =  y / self.height
        
        cam_api: CameraApi = app.camera_api
        
        cam_api.set_focus_point(focus_x, focus_y)



Builder.load_string("""
                    
<CapturePopup>:
    img: img
    size_hint: 0.6, 0.6
    Image:
        id: img
        allow_stretch: True
        keep_ratio: True
        
    
                    
<OSD_Icon>:
    canvas:
        Color:
            rgb: 1,1,0
        Line:
            rectangle: self.x, self.y, self.width, self.height
<MyCameraView>:
    app: app             
    canvas:
        Color:
            rgb: 1,1,0
            a: 0.5 * self.touched
        Line:
            width: 4
            rectangle: self.touch_pos[0], self.touch_pos[1], self.width * 0.1, self.height * 0.1
    

    OSD_Icon:
        text: 'AF' if self.state else 'MF'
        size_hint: 0.1, 0.1
        pos_hint: {"x": 0, "center_y": 0.5}
    
    OSD_Icon:
        id: exposure_mode
        state: True
        text: 'AE' if self.state else 'ME'
        size_hint: 0.1, 0.1
        pos_hint: {"center_x": 0.2, "y": 0}
        on_state: app.camera_api.auto_exposure(self.state)
        
    OSD_DropIcon:
        id: cam_select
        text: "cams"
        size_hint: 0.1, 0.1
        pos_hint: {"x": 0, "top": 1}
        
    OSD_DropIcon:
        id: res_select
        text: "res"
        size_hint: 0.1, 0.1
        pos_hint: {"right": 1, "top": 1}
    
    CaptureIcon:
        app: app
        source: "photo_capture.png"
        color: [1,1,0,1]
        #background_normal: "capture-icon.png"
        size_hint: 0.1, 0.1
        pos_hint: {"right": 0.9, "center_y": 0.5}
    Slider:
        id: zoom
        text:'zoom'
        min: 1.0
        max: 10.0
        value: 1.0
        orientation: 'vertical'
        size_hint: 0.1, 0.5
        pos_hint: {"right": 1, "center_y": 0.5}
        on_value: app.camera_api.zoom_camera(self.value)
    
    Slider:
        id: exposure
        text:'zoom'
        min: -8.0
        max: 8.0
        value: 0.0
        orientation: 'horizontal'
        size_hint: 0.5, 0.1
        pos_hint: {"center_x": 0.5, "y": 0}
        on_value: app.camera_api.set_exposure(self.value)
        disabled: exposure_mode.state
        
                
<PreviewPresets>:
    cols: 1
    
""")

Builder.load_string("""

<MainView>:
    
    BoxLayout:
        
        orientation: 'vertical'
        MyCameraView:
            id: cam
        BoxLayout:
            size_hint_y: 0.25
            Label:
                id: debug
                font_size: 8
                text_size: self.size
            BoxLayout:
                orientation: 'vertical'
                size_hint_x: 0.2
                Button:
                    id: btn0
                    text: "start_capture"
                    on_release:
                        app.camera_api.start_capture("")
                Button:
                    id: btn1
                    text: "stop_capture"
                    on_release:
                        app.camera_api.stop_capture("")

""")


class MyApp(App):
    camview_texture: Texture
    preview_buffersize: int
    
    camera_back_types = ListProperty(None)
    camera_front_types = ListProperty(None)
    
    resolutions: dict
    
    
    capture_popup: Popup
    
    def build(self):
        self.preview_buffersize = 0
        
        self.capture_popup = CapturePopup()
        
        wid = MainView()
        ids = wid.ids
        self.cam = ids.cam
        self.debug = ids.debug
        self.update_camview = self.cam.canvas.ask_update
        self.cam_select = self.cam.ids.cam_select
        self.cam_select.bind(selected=self.change_camera)

        self.res_select = self.cam.ids.res_select
        self.res_select.bind(selected=self.change_preview_preset)
        self.camera_api = CameraApi(self)
        self.set_camera_texture(1920,1080)
        
        return wid
    
    def set_camera_texture(self, width: int, height: int) -> Texture:
        print("set_camera_texture", width, height)

        tex: Texture = Texture.create(
            size=(width, height),
            colorfmt="bgra",
            bufferfmt="ubyte"
            )
        tex.flip_vertical()
        cam = self.cam
        cam.tex = tex
        
        self.camera_api.set_preview_texture(tex)
        # self.preview_buffersize = width * height * 4
        return tex
    
    
    def change_preview_preset(self,dropdown, select: str):
        res = self.resolutions[select]
        self.camera_api.select_preview_preset(res)

    def change_camera(self, dropdown: DropDown, select: str):
        index = self.camera_back_types.index(select)
        self.camera_api.select_camera(index)
        
    def on_camera_front_types(self, wid, front_types: list[str]):
        pass
    
    def on_camera_back_types(self, wid, back_types: list[str]):
        self.cam_select.icons = back_types
        

    
    
    
    
    
    
    
    #######################################################
    ############## Wrapper Callbacks ######################
    #######################################################
    
    def returned_pixel_data(self, data: bytes, width: int, height: int, pixel_count: int, tex: Texture):
        #print(len(data), pixel_count)
        #self.debug.text = str(list(data[-1024:]))
        if pixel_count != self.preview_buffersize:
            tex = self.set_camera_texture(width,height)
            data_size = len(data)
            self.preview_buffersize = pixel_count
            print("changed resolution to",width, height,data_size- pixel_count)
        if tex:
            tex.blit_buffer(data, colorfmt="bgra")
            self.update_camview()
            
            
    def returned_image_data(self, data: bytes, width: int, height: int):
        
        self.capture_popup.show_capture(data, width, height)

    def returned_thumbnail_data(self, data: bytes, width: int, height: int):
        print(len(data),width, height)
    
    def get_camera_types(self, front: list[str], back: list[str]):
        self.camera_back_types = back
        
    
    def set_preview_presets(self, presets: dict):
        self.res_select.icons = presets.keys()
        self.resolutions = presets

    

if __name__ == '__main__':
    MyApp().run()
