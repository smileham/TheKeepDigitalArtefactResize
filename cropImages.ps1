# Image crop and resize v9

param(
    [switch]$r=$false,
    [switch]$debug=$false,
    [switch]$noprofile=$false,
    [switch]$noretrim=$false,
    [string]$format="jpeg",
    [string]$profileDir = "C:\Temp\Special Collections",
    [string]$magick="C:\apps\imq8\magick.exe",
    [string]$inputFormat="tif"
)

if ($debug) {
    Write-Host "No Retrim: $noretrim"
    Write-Host "No Profile: $noprofile"
    Write-Host "Format: $format"
    Write-Host "Profile Directory: $profileDir"
    Write-Host "Magick Command: $magick"
    Write-Host "inputFormat: $inputFormat"
}

if ($r) {
    $files = Get-ChildItem -Recurse -Filter *.$inputFormat
}
else {
    $files = Get-ChildItem -Filter *.$inputFormat
}

# Create directory for final images
if(!(Test-Path -Path ./$format/ )){
    New-Item -ItemType directory -Path ./$format/
}
else {
    Write-Host "WARN: $format directory already exists"
}

#TODO: Create directory structure for recurssion

# For each input file in directory
for ($i=0; $i -lt $files.Count; $i++) {

    $file = $files[$i].fullname+"[0]"
    #$newFile = $file.split(".$inputFormat")[0]
    $newFile = $files[$i].name.split(".$inputFormat")[0]
    $foundSplit=$false

    # trim the outside grey - this is only to get the final image height and image offset (hence the info)
    $imageProcess = Invoke-Expression "$magick convert '$file' -quiet -sample 5% -resize 1000% -fuzz 17% -trim -format '%wx%h%O!' -write info: +repage -crop 50x -bordercolor '#8B9093' -border 1x1 -fuzz 11% -trim -format '%wx%h%O,' info:"

    $output = $imageProcess.split("!")[0]
    # Filter out any blank bars
    $swatchSplitArray = ($imageProcess -split "1x1-1-1").where({$_ -ne ","})
    
    # If I have more than two parts to my image, crop a little harder.
    if ($swatchSplitArray.count -gt 2) {
        Write-Host "WARN: Crop Error - Increase Fuzz: $file"
        $imageProcess = Invoke-Expression "$magick convert '$file' -quiet -sample 5% -resize 1000% -fuzz 23% -trim -format '%wx%h%O!' -write info: +repage -crop 50x -bordercolor '#8B9093' -border 1x1 -fuzz 11% -trim -format '%wx%h%O,' info:"
        
        $output = $imageProcess.split("!")[0]
        $swatchSplit = ($imageProcess -split "1x1-1-1")[0]
    }
    else {
        $swatchSplit = $swatchSplitArray[0]
    }

    $swatch = $swatchSplit.split(",").Count-1

    if (-not($swatchSplit.length -eq $imageProcess.length)) {
        if ($debug) {Write-Host "DEBUG: Split: $swatch"}
        # Each strip is 50 pixels wide, so multiply by 50 and that is the new width
        $newOutput = ($swatch*50).toString()+"x"+$output.split('x')[1]
        $boundary = $newOutput
        $foundSplit = $true
    }
    else {
        Write-Host "WARN: Cannot remove Swatch: $file"
        $boundary = $output
    }

    
    if ($debug) {Write-Host "INFO: Original Image: $file"}
    if ($debug) {Write-Host "INFO: Converted Image: $newFile.$format"}

    $profileCommand = if (-not $noprofile) {"-profile '$profileDir\AdobeRGB1998.icc' -profile '$profileDir\sRGB.icc'"} else {""}

    if ($foundSplit -and (-not $noretrim)) {
        $resizeCommand ="-write mpr:orig -resize 5% -resize 1000% -crop $boundary -bordercolor '#8B9093' -border 1x1 -fuzz 15% -trim -set option:trimzone '%[fx:(w*2)+200]x%[fx:(h*2)+200]+%[fx:(page.x*2)-100]+%[fx:(page.y*2)-100]' +delete mpr:orig -set option:distort:viewport %[trimzone] -filter point -distort SRT 0 +repage"
    }
    else {
        # As the original image size was halved for the blur, double all the sizes now.
        $newBoundary = $boundary.split('x')
        $newWidth = ([int]$newBoundary[0]*2+200)
        if ($noretrim) {$newWidth=$newWidth-100}
        $newHeight = ([int]$newBoundary[1].split('+')[0]*2+200)
        $newXOffset = ([int]$newBoundary[1].split('+')[1]*2-100)
        $newYOffset = ([int]$newBoundary[1].split('+')[2]*2-100)

        $newBoundary = $newWidth.toString()+"x"+$newHeight.toString()+"+"+$newXOffset.toString()+"+"+$newYOffset.toString()

        $resizeCommand = "-crop $newBoundary"
    }

    $formatCommand =""

    if ($format -eq "jpeg") {
        $formatCommand ="-define jpeg:extent=1024kb"
    }
    if ($format -eq "png") {
        $formatCommand ="-quality 75"
    }
    
    $magickCommand = "convert '$file' -quiet $profileCommand $resizeCommand -resize 10000000>@ $formatCommand ./$format/$newFile.$format"

    # Save as a 10 megapixel jpeg (if the cropped image is large enough)
    if ($debug) {Write-Host "DEBUG: Magick Command: $magickCommand"}
    Invoke-Expression "$magick $magickCommand"
}
