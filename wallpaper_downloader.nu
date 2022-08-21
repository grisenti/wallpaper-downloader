#!/usr/local/bin/nu

let data = (fetch https://reddit.com/r/WidescreenWallpaper/hot/.json | get data | get children)
let image-path = "/home/grisenti/Pictures/Wallpapers/daily/"
let present-images = (ls $image-path | get name | path basename)
let res-w = 3440
let res-h = 1440

def download [url : string, path : string] {
  fetch --raw $url
  | save -r $path
}

def set-wallpaper [path : string] {
  gsettings set org.gnome.desktop.background picture-uri-dark ('"file://' + $path + '"')
}

def store-old [path : string] {
  let old_wallpapers = (ls -l $path | where created < (date now) - 1wk | get name)
  $old_wallpapers | each {|it| mv $it ($path + "/archive")}
}

def is-gallery [post] {
  $post | get url | $in =~ "gallery"
}

def process-gallery-item [image-data] {
  let w = ($image-data | get s | get x | first | into int)
  let h = ($image-data | get s | get y | first | into int)
  let extension = ($image-data | get m | first | path basename)
  let id = ($image-data | get id | first)
  if ($res-w == $w and $res-h == $h) {
    [[name url]; [$id $"https://i.redd.it/($id).($extension)"]]
  }
}

def process-gallery [post] {
  $post | get media_metadata | transpose key value |each {|it| $it | get value | process-gallery-item $in}
}

def process-image-post [post] {
  $post | select title url | where title =~ $"($res-w)x($res-h)" | rename name url
}

def process-post [post] {
  let post-data = ($post | get data)
  if (is-gallery $post-data) {
    process-gallery $post-data
  } else {
    process-image-post $post-data
  }
}

def main [] {
  let selected = ($data | each { |it| process-post $it} | flatten)
  echo $selected
  let selected = ($selected | flatten | where name not-in $present-images | first)
  let downloaded-path = ($image-path + $selected.name)
  download $selected.url $downloaded-path
  set-wallpaper $downloaded-path
  store-old $image-path
}
