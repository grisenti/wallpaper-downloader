#!/usr/bin/env nu

def get_data [] {
  fetch https://reddit.com/r/WidescreenWallpaper/hot/.json 
  | get data 
  | get children 
  | each {|it| $it | get data | select url title}
}

def select_images [path : string] {
  let selection = ($in | where url =~ ".png" or url =~ ".jpg" | where title =~ "3440x1440")  
  echo $selection
  let images = (ls $path | get name | path basename) 
  echo $images
  $selection | where title not-in $images
}

def download [url : string, path : string] {
  fetch --raw $url
  | save -r $path
}

def set_wallpaper [path : string] {
  gsettings set org.gnome.desktop.background picture-uri-dark ('"file://' + $path + '"')
} 

def main [] {
  let w_path = "/home/grisenti/Pictures/Wallpapers/daily/"
  let images = (get_data | select_images $w_path)
  echo $images
  if ( not ($images | empty?)) {
    let wallpaper = ($images | first)
    let path = ($w_path + $wallpaper.title)
    download $wallpaper.url $path 
    set_wallpaper $path
  }
}
