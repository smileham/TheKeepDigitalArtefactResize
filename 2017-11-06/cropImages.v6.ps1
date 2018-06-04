# Image crop and resize v6 - Metrics based on folder of 20 30megapixel TIFF images.
# Run on Q16
# Days              : 0
# Hours             : 0
# Minutes           : 0
# Seconds           : 54
# Milliseconds      : 895
# Ticks             : 548956420
# TotalDays         : 0.000635366226851852
# TotalHours        : 0.0152487894444444
# TotalMinutes      : 0.914927366666667
# TotalSeconds      : 54.895642
# TotalMilliseconds : 54895.642

# Run on Q8
# Days              : 0
# Hours             : 0
# Minutes           : 0
# Seconds           : 44
# Milliseconds      : 206
# Ticks             : 442065253
# TotalDays         : 0.00051164959837963
# TotalHours        : 0.0122795903611111
# TotalMinutes      : 0.736775421666667
# TotalSeconds      : 44.2065253
# TotalMilliseconds : 44206.5253

# Padding for Border
$offset = 200;

$files = Get-ChildItem -Filter *.tif

# Create Scratch directory for temporary files
New-Item -path ./scratch/ -ItemType directory

# Create directory for final JPEG images
New-Item -path ./jpeg/ -ItemType directory

# For each TIFF file in directory
for ($i=0; $i -lt $files.Count; $i++) {

    $file = $files[$i].name+"[0]"
    $newFile = $file.split(".tif")[0]

    # trim the outside grey - this is only to get the final image height and image offset (hence the info)
    $output = C:\apps\imq8\magick.exe convert $file -quiet -sample 5% -resize 1000% -write ./scratch/$newFile.bmp -fuzz 17% -trim -format '%wx%h%O' -write info: +repage -crop 50x -bordercolor '#8B9093' -border 1x1 -fuzz 10% -trim ./scratch/$newFile-blur_%d.bmp

    # The smallest image will have the smallest file size, sort by size and name
    $strips = Get-ChildItem -Filter ./scratch/$newFile-blur_*.bmp | Sort-Object -Property @{expression ="Length"; ascending=$True}, @{expression ="Name"; ascending=$True}

    $foundSplit = $false;

    # Get the first (smallest) file.
    $strip = $strips[0].name
    if ($strips[0].length -gt 142) {
        # Attempt to trim the image by the grey colour of the background
        $width = C:\apps\imq8\magick.exe identify -format '%w' ./scratch/$strip

        # If the image was just the grey background, the new size will be a 1x1 pixel.  This means that it must be the gap between the Artefact and the Colour swatch
        if ($width -eq "1") {
            $foundSplit = $true
            "DEBUG: Found by pixel: "+$strip
        }
        else {
            "WARN: Cannot remove Swatch: "+$file
            $boundary = $output
        }
    }
    else {
        $foundSplit = $true
        "DEBUG: Found by filesize: "+$strip
    }
    
    if ($foundSplit) {
        # Find the file name of the strip of image, each strip is 50 pixels wide, so multiply by 50 and that is the new width
        $stripSplit = $strip.split("_")

        $stripNumber = [int]$stripSplit[$stripSplit.Count-1].split('.')[0]
        $newOutput = (($stripNumber-1)*50).toString()+"x"+$output.split('x')[1]

        # Retrim incase the process has added/removed some space around the image (due to the swatch)
        $boundary = C:\apps\imq8\magick.exe convert ./scratch/$newFile.bmp -crop $newOutput -bordercolor '#8B9093' -border 1x1 -fuzz 15% -trim -format '%wx%h%O' info:
    }
    

    # As the original image size was halved for the blur, double all the sizes now.
    $newBoundary = $boundary.split('x')
    $newWidth = ([int]$newBoundary[0]*2)+$offset
    $newHeight = ([int]$newBoundary[1].split('+')[0]*2)+$offset
    $newXOffset = ([int]$newBoundary[1].split('+')[1]*2)-($offset/2)
    $newYOffset = ([int]$newBoundary[1].split('+')[2]*2)-($offset/2)

    $newBoundary = $newWidth.toString()+"x"+$newHeight.toString()+"+"+$newXOffset.toString()+"+"+$newYOffset.toString()

    "INFO: Original Image: "+$file
    "INFO: Converted Image: "+$newFile+".jpeg"

    # Save as a 10 megapixel jpeg (if the cropped image is large enough)
    C:\apps\imq8\magick.exe convert $file -profile "C:\Temp\Special Collections\AdobeRGB1998.icc" -profile "C:\Temp\Special Collections\sRGB.icc" -quiet -crop $newBoundary -resize 10000000>@ -define jpeg:extent=1024kb ./jpeg/$newFile.jpeg
    #C:\apps\imq8\magick.exe convert $file -quiet -crop $newBoundary -resize 10000000>@ -define jpeg:extent=1024kb ./jpeg/$newFile.jpeg
}

# Tidy up the scratch directory.
Remove-Item -Path ./scratch/ -Recurse