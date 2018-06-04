# Image crop and resize v3 - Metrics based on folder of 20 30megapixel TIFF images.
# Days              : 0
# Hours             : 0
# Minutes           : 1
# Seconds           : 59
# Milliseconds      : 991
# Ticks             : 1199917840
# TotalDays         : 0.0013887937962963
# TotalHours        : 0.0333310511111111
# TotalMinutes      : 1.99986306666667
# TotalSeconds      : 119.991784
# TotalMilliseconds : 119991.784

$files = Get-ChildItem -Filter *.tif

# Create Scratch directory for temporary files
mkdir ./scratch/

# Create directory for final Jpeg images
mkdir ./jpeg/

# For each TIFF file in directory
for ($i=0; $i -lt $files.Count; $i++) {

    $file = $files[$i].name+"[0]"
    $newFile = $file.split(".tif")[0]

    # Don't need full detail for cropping, half the image size then Blur the image
    magick convert $file -quiet -resize 50% -virtual-pixel edge -blur 0x5 ./scratch/$file-blur.bmp

    # trim the outside grey - this is only to get the final image height and image offset (hence the info)
    $output = magick convert ./scratch/$file-blur.bmp -fuzz 15% -trim -format '%wx%h%O' info:

    # Crop the image based on the output of the previous command, blur the picture again, cut into 50 pixel strips, then trim off the grey.
    magick convert ./scratch/$file-blur.bmp -crop $output +repage -quiet -crop 50x -bordercolor '#8B9093' -border 1x1 -fuzz 10% -trim ./scratch/$file-blur_%d.bmp

    # The smallest image will have the smallest file size, sort by size and name
    $strips = Get-ChildItem -Filter ./scratch/$file-blur_*.bmp | Sort-Object -Property @{expression ="Length"; ascending=$True}, @{expression ="Name"; ascending=$True}

    $foundSplit = $false;

    # For each of the strips of image (smallest one should be first)
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

        # Find the file name of the strip of image, each strip is 50 pixels wide, so multiply by 50 and that is the new width
        $stripSplit =$strip.split("_")

        $stripNumber = [int]$stripSplit[$stripSplit.Count-1].split('.')[0]
        $newOutput = ($stripNumber*50).toString()+"x"+$output.split('x')[1]

        # Retrim incase the process has added/removed some space around the image (due to the swatch)
        $boundary = magick convert ./scratch/$file-blur.bmp -crop $newOutput -bordercolor '#8B9093' -border 1x1 -fuzz 15% -trim -format '%wx%h%O' info:
    }
    else {
        "WARN: Cannot remove Swatch: "+$file
        $boundary = $output
    }
    # Add some padding
    $offset = 200;

    # As the original image size was halved for the blur, double all the sizes now.
    $nw = $boundary.split('x')
    $nb = $nw[1].split('+')
    $newWidth = ([int]$nw[0]*2)+$offset
    $newHeight = ([int]$nb[0]*2)+$offset
    $newXOffset = ([int]$nb[1]*2)-($offset/2)
    $newYOffset = ([int]$nb[2]*2)-($offset/2)

    $newBoundary = $newWidth.toString()+"x"+$newHeight.toString()+"+"+$newXOffset.toString()+"+"+$newYOffset.toString()

    "INFO: Original Image: "+$file
    "INFO: Converted Image: "+$newFile+".jpeg"

    # Save as a 10 megapixel jpeg
    magick convert $file -quiet -crop $newBoundary -resize 10000000@ -quality 98 -define jpeg:extent=1024kb ./jpeg/$newFile.jpeg
}

# Tidy up the scratch directory.
rm -r ./scratch/