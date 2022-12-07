#!/usr/local/bin/nu

let data = (fetch https://reddit.com/r/WidescreenWallpaper/hot/.json | get data | get children)
let image_path = "/home/grisenti/Pictures/Wallpapers/daily/"
let present_images = (ls $image_path | get name | path basename)
let res_w = 3440
let res_h = 1440

def download [url : string, path : string] {
  fetch --raw $url
  | save -r $path
}

def set-wallpaper [path : string] {
  gsettings set org.gnome.desktop.background picture-uri-dark ('"file://' + $path + '"')
}

def store-old [path : string] {
  let old_wallpapers = (ls -l $path | where type == file | where created < (date now) - 1wk)
  if (not ($old_wallpapers | is-empty)) {
    $old_wallpapers | get name | each {|it| mv $it ($path + "/archive")}
  }
}

def is-gallery [post] {
  $post | get url | $in =~ "gallery"
}

def process-gallery-item [image_data] {
  let w = ($image_data | get s | get x | into int)
  let h = ($image_data | get s | get y | into int)
  let extension = ($image_data | get m | path basename)
  let id = ($image_data | get id)
  if ($res_w == $w and $res_h == $h) {
    [[name url]; [$id $"https://i.redd.it/($id).($extension)"]]
  }
}

def process-gallery [post] {
  $post | get media_metadata | transpose key value |each {|it| $it | get value | process-gallery-item $in}
}

def process-image-post [post] {
  $post | select title url | where title =~ $"($res_w)x($res_h)" | rename name url
}

def process-post [post] {
  let post_data = ($post | get data)
  if (is-gallery $post_data) {
    process-gallery $post_data
  } else {
    process-image-post $post_data
  }
}

def main [] {
  let selected = ($data | each { |it| process-post $it} | flatten)
  echo $selected
  let selected = ($selected | flatten | where name not-in $present_images | first)
  let downloaded_path = ($image_path + $selected.name)
  download $selected.url $downloaded_path
  set-wallpaper $downloaded_path
  store-old $image_path
}
