# Wallpaper Downloader
downloads wallpapers from reddit (currently from r/WidescreenWallpapers and r/wallpaper) and sets them using `gsetting` on gnome. 
If there aren't any new images to download, it randomly picks a wallpaper from an archive, where images from the target folder are moved to periodically.
# Setting it up
first change screen width, height and download path, then compile the program with 
```
nim c -d:release -d:ssl wallpaper_downloader.nim
```
Both the download path folder and the `archive` folder inside it should exist before running the program
