# Days              : 0
# Hours             : 0
# Minutes           : 2
# Seconds           : 10
# Milliseconds      : 562
# Ticks             : 1305620365
# TotalDays         : 0.00151113468171296
# TotalHours        : 0.0362672323611111
# TotalMinutes      : 2.17603394166667
# TotalSeconds      : 130.5620365
# TotalMilliseconds : 130562.0365

$files = Get-ChildItem -Filter *.tif

# Create Scratch directory for temporary files
mkdir ./scratch/

# Create directory for final Jpeg images
mkdir ./jpeg/

# For each TIFF file in directory
for ($i=0; $i -lt $files.Count; $i++) {

    $file = $files[$i].name+"[0]"
    $newFile = $file.split(".tif")[0]

    # Blur the image and trim the outside grey - this is only to get the final image height and image offset (hence the info)
    magick convert $file -quiet -virtual-pixel edge -blur 0x9 ./scratch/$file-blur.bmp

    $output = magick convert ./scratch/$file-blur.bmp -fuzz 15% -trim -format '%wx%h%O' info:
    # Crop the image based on the output of the previous command, blur the picture again, and cut into 100 pixel strips.
    magick convert ./scratch/$file-blur.bmp -crop $output +repage -quiet -crop 100x -bordercolor '#8B9093' -border 1x1 -fuzz 10% -trim ./scratch/$file-blur_%d.bmp

    $strips = Get-ChildItem -Filter ./scratch/$file-blur_*.bmp | Sort-Object -Property @{expression ="Length"; ascending=$True}, @{expression ="Name"; ascending=$True}

    $foundSplit = $false;

    # For each of the strips of image
    for ($j=0; $j -lt $strips.Count -and !$foundSplit; $j++) {
        $strip = $strips[$j].name

        # Attempt to trim the image by the grey colour of the background
        $width = magick identify -format '%w' ./scratch/$strip

        # If the image was just the grey background, the new size will be a 1x1 pixel.  This means that it must be the gap between the Artefact and the Colour swatch
        if ($width -eq "1") {
            $foundSplit = $true
        }
    }
    
    if ($foundSplit) {

        # Find the file name of the strip of image, each strip is 100 pixels wide, so multiply by 100 and that is the new width
        $stripSplit =$strip.split("_")

        $stripNumber = [int]$stripSplit[$stripSplit.Count-1].split('.')[0]
        $newOutput = ($stripNumber*100).toString()+"x"+$output.split('x')[1]

        $boundary = magick convert ./scratch/$file-blur.bmp -crop $newOutput -bordercolor '#8B9093' -border 1x1 -fuzz 15% -trim -format '%wx%h%O' info:
    }
    else {
        "WARN: Cannot remove Swatch: "+$file
        $boundary = $output
    }
        # Add some padding
        $offset = 200;

        $newBoundary = $boundary.split('x')
        $newWidth = [int]$newBoundary[0]+$offset
        $newHeight = [int]$newBoundary[1].split('+')[0]+$offset
        $newXOffset = [int]$newBoundary[1].split('+')[1]-($offset/2)
        $newYOffset = [int]$newBoundary[1].split('+')[2]-($offset/2)

        $newBoundary = $newWidth.toString()+"x"+$newHeight.toString()+"+"+$newXOffset.toString()+"+"+$newYOffset.toString()

        "INFO: Original Image: "+$file
        "INFO: Converted Image: "+$newFile+".jpeg"

        magick convert $file -quiet -crop $newBoundary -resize 10000000@ -quality 98 -define jpeg:extent=1024kb ./jpeg/$newFile.jpeg
}

# Tidy up the scratch directory.
rm -r ./scratch/