from swift_types import *


class CameraApi:

    def set_preview_texture(tex: object): ...

    def start_capture(mode: str): ...

    def stop_capture(mode: str): ...

    def set_camera_mode(mode: str): ...

    def select_camera(index: long): ...

    def take_photo(): ...

    def take_multi_photo(count: long): ...
    
    def select_preview_preset(preset:str): ...
    
    def set_focus_point(x: double, y: double): ...
    
    def zoom_camera(zoom: double): ...
    
    def set_exposure(value: double): ...
    
    def auto_exposure(state: bool): ...

    @callback
    def returned_image_data(data: data, width: long, height: long): ...

    @callback
    def returned_thumbnail_data(data: data, width: long, height: long): ...
    
    @callback
    def returned_pixel_data(data: data,width: long, height: long, pixel_count: long, tex: object): ...
    
    @callback
    def change_cam_res(width: long, height: long): ...

    @callback
    def get_camera_types(front: jsondata, back: jsondata): ...
    
    
    
    
    
    @callback
    def set_preview_presets(presets: jsondata): ...
    