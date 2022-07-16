#!/usr/bin/env nu

def get_data [] {
  fetch https://reddit.com/r/WidescreenWallpaper/hot/.json 
  | get data 
  | get children 
  | each {|it| $it | get data | select url title}
}

def select_images [] {
  where url =~ ".png" or url =~ ".jpg" | where title =~ "[3440x1440]"
}

def download [url : string, path : string] {
  fetch --raw $url
  | save -r $path
}

def set_wallpaper [path : string] {
  gsettings set org.gnome.desktop.background picture-uri-dark ('"file://' + $path + '"')
} 

def main [] {
  let images = (get_data | select_images)
  echo $images
  let wallpaper = ($images | first)
  let path = ("/home/grisenti/Pictures/Wallpapers/daily/" + $wallpaper.title)
  download $wallpaper.url $path 
  set_wallpaper $path
}
