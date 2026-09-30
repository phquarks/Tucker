app = defines["app"]
guide = defines["guide"]

files = [
    (app, "Tucker.app"),
    (guide, "Installation Guide.txt"),
]
symlinks = {"Applications": "/Applications"}

volume_name = "Tucker"
format = "UDZO"
filesystem = "APFS"
compression_level = 9

background = defines["background"]
window_rect = ((120, 120), (720, 460))
default_view = "icon-view"
show_toolbar = False
show_status_bar = False
show_pathbar = False
show_sidebar = False

icon_size = 96
text_size = 13
label_pos = "bottom"
arrange_by = None
show_icon_preview = False
icon_locations = {
    "Tucker.app": (195, 155),
    "Applications": (525, 155),
    "Installation Guide.txt": (360, 320),
}

hide_extensions = ["Tucker.app"]
