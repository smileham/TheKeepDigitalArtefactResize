# Days              : 0
# Hours             : 0
# Minutes           : 3
# Seconds           : 16
# Milliseconds      : 29
# Ticks             : 1960292057
# TotalDays         : 0.0022688565474537
# TotalHours        : 0.0544525571388889
# TotalMinutes      : 3.26715342833333
# TotalSeconds      : 196.0292057
# TotalMilliseconds : 196029.2057

$files = Get-ChildItem -Filter *.tif

# Create Scratch directory for temporary files
mkdir ./scratch/

# Create directory for final Jpeg images
mkdir ./jpeg/

# For each TIFF file in directory
for ($i=0; $i -lt $files.Count; $i++) {

    $file = $files[$i].name+"[0]"

    # Blur the image and trim the outside grey - this is only to get the final image height and image offset (hence the info)
    $output = magick $file -virtual-pixel edge -blur 0x15 -fuzz 15% -trim -format '%wx%h%O' info:

    # Crop the image based on the output of the previous command, blur the picture again, and cut into 100 pixel strips.
    magick convert $file -crop $output +repage -virtual-pixel edge -blur 0x15 -quiet -crop 100x ./scratch/$file-blur_%d.jpeg

    $strips = Get-ChildItem -Filter ./scratch/$file-blur_*.jpeg

    $foundSplit = $false;

    # For each of the strips of image
    for ($j=0; $j -lt $strips.Count -and !$foundSplit; $j++) {
        $strip = $strips[$j].name

        # Attempt to trim the image by the grey colour of the background
        $width = magick ./scratch/$strip -bordercolor '#8B9093' -border 1x1 -fuzz 10% -trim +repage -format %w  info:

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
    }
    else {
        # If we didn't find a "background" strip, then just crop to the original boundary
        $newOutput = $output
    }   

    # Crop the image based on the new size, and then try and trim it one last time, just in case there is still some background left from this process.
    # Then resize to 1MB.
    $newFile = $file.split(".tif")[0]
    magick convert $file -crop $newOutput -bordercolor '#8B9093' -border 1x1 -fuzz 25% -trim +repage -resize 10000000@ -quality 98 -define jpeg:extent=1024kb ./jpeg/$newFile.jpeg

}

# Tidy up the scratch directory.
rm -r ./scratch/