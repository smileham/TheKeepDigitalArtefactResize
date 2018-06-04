# Image crop and resize v6 - Metrics based on folder of 20 30megapixel TIFF images.
# Run on Q8
# Days              : 0
# Hours             : 0
# Minutes           : 0
# Seconds           : 52
# Milliseconds      : 496
# Ticks             : 524968140
# TotalDays         : 0.000607602013888889
# TotalHours        : 0.0145824483333333
# TotalMinutes      : 0.8749469
# TotalSeconds      : 52.496814
# TotalMilliseconds : 52496.814
#
# With -noretrim and -noprofile
# Days              : 0
# Hours             : 0
# Minutes           : 0
# Seconds           : 39
# Milliseconds      : 702
# Ticks             : 397024948
# TotalDays         : 0.000459519615740741
# TotalHours        : 0.0110284707777778
# TotalMinutes      : 0.661708246666667
# TotalSeconds      : 39.7024948
# TotalMilliseconds : 39702.4948

param([switch]$noretrim=$false, [switch]$debug=$false, [switch]$noscratch=$false, [switch]$noprofile=$false)

if ($debug) {Write-Host "Arg: $noretrim"}

# Padding for Border
$offset = 200;

$files = Get-ChildItem -Filter *.tif

# Create directory for final JPEG images
if(!(Test-Path -Path ./jpeg/ )){
    New-Item -ItemType directory -Path ./jpeg/
}
else {
    Write-Host "WARN: JPEG directory already exists"
}

if (-not $noscratch) {
    if(!(Test-Path -Path $env:temp/scratch/ )){
        New-Item -Path $env:temp/scratch/ -ItemType directory
    }
    else {
        Write-Host "WARN: temp/scratch directory already exists"
    }
}

# For each TIFF file in directory
for ($i=0; $i -lt $files.Count; $i++) {

    $file = $files[$i].name+"[0]"
    $newFile = $file.split(".tif")[0]

    # trim the outside grey - this is only to get the final image height and image offset (hence the info)
    #$output = C:\apps\imq8\magick.exe convert $file -quiet -sample 5% -resize 1000% -write ./scratch/$newFile.bmp -fuzz 17% -trim -format '%wx%h%O' -write info: -quiet +repage -crop 50x -bordercolor '#8B9093' -border 1x1 -fuzz 10% -trim ./scratch/$newFile-blur_%d.bmp
    if ($noscratch) {$imageProcess = C:\apps\imq8\magick.exe convert $file -quiet -sample 5% -resize 1000% -fuzz 17% -trim -format '%wx%h%O!' -write info: +repage -crop 50x -bordercolor '#8B9093' -border 1x1 -fuzz 10% -trim -format '%wx%h%O,' info:}
    else {$imageProcess = C:\apps\imq8\magick.exe convert $file -quiet -sample 5% -resize 1000% -write $env:temp/scratch/$newFile.bmp -fuzz 17% -trim -format '%wx%h%O!' -write info: +repage -crop 50x -bordercolor '#8B9093' -border 1x1 -fuzz 10% -trim -format '%wx%h%O,' info:}

    $output = $imageProcess.split("!")[0]

    # The smallest image will have the smallest file size, sort by size and name
    # $strips = Get-ChildItem -Filter ./scratch/$newFile-blur_*.bmp | Sort-Object -Property @{expression ="Length"; ascending=$True}, @{expression ="Name"; ascending=$True}

    $swatchSplit = ($imageProcess -split "1x1-1-1")[0]

    $swatch = $swatchSplit.split(",").Count-1

    if (-not($swatchSplit.length -eq $imageProcess.length)) {
        if ($debug) {Write-Host "DEBUG: Split: $swatch"}
        
        # Find the file name of the strip of image, each strip is 50 pixels wide, so multiply by 50 and that is the new width
        $newOutput = ($swatch*50).toString()+"x"+$output.split('x')[1]

        if (-not $noretrim) {
            # Retrim incase the process has added/removed some space around the image (due to the swatch)
            if ($noscratch) {$boundary = C:\apps\imq8\magick.exe convert $file -quiet -sample 5% -resize 1000% -crop $newOutput -bordercolor '#8B9093' -border 1x1 -fuzz 15% -trim -format '%wx%h%O' info:}
            else {$boundary = C:\apps\imq8\magick.exe convert $env:temp/scratch/$newFile.bmp -quiet -crop $newOutput -bordercolor '#8B9093' -border 1x1 -fuzz 15% -trim -format '%wx%h%O' info:}
        }
        else {
            $boundary = $newOutput
        }
    }
    else {
        Write-Host "WARN: Cannot remove Swatch: $file"
        $boundary = $output
    }
    

    # As the original image size was halved for the blur, double all the sizes now.
    $newBoundary = $boundary.split('x')
    $newWidth = ([int]$newBoundary[0]*2)+$offset
    $newHeight = ([int]$newBoundary[1].split('+')[0]*2)+$offset
    $newXOffset = ([int]$newBoundary[1].split('+')[1]*2)-($offset/2)
    $newYOffset = ([int]$newBoundary[1].split('+')[2]*2)-($offset/2)

    $newBoundary = $newWidth.toString()+"x"+$newHeight.toString()+"+"+$newXOffset.toString()+"+"+$newYOffset.toString()

    if ($debug) {Write-Host "INFO: Original Image: $file"}
    if ($debug) {Write-Host "INFO: Converted Image: $newFile.jpeg"}

    # Save as a 10 megapixel jpeg (if the cropped image is large enough)
    if (-not $noprofile) {C:\apps\imq8\magick.exe convert $file -profile "C:\Temp\Special Collections\AdobeRGB1998.icc" -profile "C:\Temp\Special Collections\sRGB.icc" -quiet -crop $newBoundary -resize 10000000>@ -define jpeg:extent=1024kb ./jpeg/$newFile.jpeg}
    else {C:\apps\imq8\magick.exe convert $file -quiet -crop $newBoundary -resize 10000000>@ -define jpeg:extent=1024kb ./jpeg/$newFile.jpeg}
}

# Tidy up the scratch directory.
if (-not $noscratch) {Remove-Item -Path $env:temp/scratch/ -Recurse}
