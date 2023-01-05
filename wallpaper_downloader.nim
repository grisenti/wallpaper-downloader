import std/httpclient
import std/json
import std/[times, os]
import std/sequtils
import std/sugar
import std/strutils
import std/[tables, sets]
import std/strformat
import std/random

const screen_width = 3440
const screen_height = 1440
const download_path = "/home/grisenti/Pictures/Wallpapers/daily/"

func normalize(name: string): string =
  name.replace("/", "-")

proc getData(): JsonNode =
  var client = newHttpClient()
  let content = parseJson(client.getContent("https://reddit.com/r/WidescreenWallpaper/hot/.json"))
  content["data"]["children"]

func isGallery(post: JsonNode): bool =
  post["url"].getStr().contains("gallery")

proc galleryItemUrl(gallery_item: JsonNode): string =
  let id = gallery_item["id"].getStr
  let extension = gallery_item["m"].getStr.splitPath.tail
  let image_data = gallery_item["s"]
  let width = image_data["x"].getInt
  let height = image_data["y"].getInt
  if width == screen_width and height == screen_height:
    return fmt"https://i.redd.it/{id}.{extension}"
  return ""

proc processGallery(gallery_post: JsonNode): seq[(string, string)] =
  let name = gallery_post["title"].getStr
  var count = 0
  for _, item in gallery_post["media_metadata"].getFields.pairs:
    let url = galleryItemUrl(item)
    if url != "":
      result.add((fmt"{name.normalize} {count}", url))
    count += 1

proc processImage(image_post: JsonNode): seq[(string, string)] =
  let title = image_post["title"].getStr
  if title.contains(fmt"{screen_width}x{screen_height}"):
    return @[(title.normalize, image_post["url"].getStr)]
  echo title, " was not selected"
  @[]

proc processData(data: JsonNode): seq[(string, string)] =
  for post in data:
    let post = post["data"]
    result.add(
    if post.isGallery:
      processGallery(post)
    else:
      processImage(post)
    )

proc getAlreadyDownloaded(): HashSet[string] =
  walkFiles(download_path & "*")
    .toSeq
    .map(file => file.splitPath.tail)
    .toHashSet

proc download(image_info: (string, string)): string =
  var client = newHttpClient()
  let image = client.getContent(image_info[1])
  let image_file = download_path & image_info[0]
  let file = open(image_file, fmWrite)
  file.write(image)
  image_file

proc storeOld() =
  for file in walkFiles(download_path & "*"):
    let info = file.getFileInfo
    if info.lastWriteTime < (getTime() - weeks(2)):
      echo "moving ", file, " to archive"
      moveFile(file, download_path & "archive/" & file.splitPath.tail)

let data = getData()
let available = processData(data)
echo available
let already_downloaded = getAlreadyDownloaded()
let selected = available.filter(image => (image[0] notin already_downloaded))
let new_wallpaper = if selected.len == 0:
  sample(already_downloaded.toSeq)
else:
  download(selected[0])
echo "setting wallpaper: ", new_wallpaper
discard execShellCmd("gsettings set org.gnome.desktop.background picture-uri-dark \"file://" &
    new_wallpaper & "\"")
storeOld()


