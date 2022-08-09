#!/usr/local/bin/nu

def get_data [] {
  fetch https://reddit.com/r/WidescreenWallpaper/hot/.json 
  | get data 
  | get children 
  | each {|it| $it | get data | select url title}
}

def select_images [path : string] {
  let selection = ($in | where url =~ "png" or url =~ "jpg" 
                       | where title =~ "3440x1440" or title =~ "21:9")  
  let images = (ls $path | get name | path basename) 
  $selection | where title not-in $images
}

def download [url : string, path : string] {
  fetch --raw $url
  | save -r $path
}

def set_wallpaper [path : string] {
  gsettings set org.gnome.desktop.background picture-uri-dark ('"file://' + $path + '"')
} 

def store-old [path : string] {
  let old_wallpapers = (ls -l $path | where created < (date now) - 1wk | get name)
  $old_wallpapers | each {|it| mv $it ($path + "/archive")}
}

def change-wallpaper [path : string] {
  let images = (get_data | select_images $path)
  if ( not ($images | empty?)) {
    let wallpaper = ($images | first)
    let path = ($path + $wallpaper.title)
    download $wallpaper.url $path 
    set_wallpaper $path
  }
  
}

def main [] {
  let w_path = "/home/grisenti/Pictures/Wallpapers/daily/"
  if (ls -l $w_path | where created > (date now) - 1day | empty?) {
    change-wallpaper $w_path
  } else {
    echo "daily wallpaper already downloaded"
  }
  #store-old $w_path
}
