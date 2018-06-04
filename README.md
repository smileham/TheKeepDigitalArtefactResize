---
title: 'The Keep - Digital Preservation Image Resizing'
version: 0.1
date: 04/06/2017
author: Steven Mileham
output: word_document
---
# The Keep --- Digital Preservation Image Resizing

[TOC]

## Background

Whilst discussing cloud storage for digital artefacts with the technologist from [The Keep](http://www.thekeep.info/), Adam Harwood mentioned their current workflow for preserving a number of artefacts.

> The German and Jewish collections held by Special Collections at The Keep reflect the study of political, social, literary and intellectual German-Jewish history, in particular the history of Jewish refugees and their families to the United Kingdom during and after the Second World War.
>
> As part of a Rothschild funded project to catalogue and digitise the collections, Special Collections will make 10,000 digital scans available to view online through The Keep’s online catalogue.  The University’s instance of Box will be used as storage for these images and will be accessed through the Box API by an interface developed by The Keep’s website developers [Orangeleaf](https://www.orangeleaf.com/).  Images will be resized and uploaded to box using an ImageMagick script.
>
> This project is inline with Special Collections operational plans to make as many collections as possible available online over the next five years.  The infrastructure established in this project can support more collections being made available online in the future.

[The Centre for German-Jewish studies](http://www.sussex.ac.uk/cgjs/) is currently digitising around 10,000 letters, photographs and documents.  Each of these artefacts is photographed at high resolution and stored as a TIFF file by an archivist.  Then a number of volunteers load the image in to an image editing application and resize/crop the image for use online.  This struck me as an ideal opportunity for automation.

I have now written a PowerShell script using [ImageMagick](https://www.imagemagick.org/script/index.php) to take the original image, crop to the artefact and resize the image to the equivalent of a 10 megapixel photograph, before saving the resulting JPEG to be less than 1MB.  The complexity to be overcome is that all the images are captured alongside a colour swatch to enable faithful recreation of the colour range.

The Keep have provided a sample set of 20 TIFF images to test with.  The script now crops and resizes these images in 54 seconds.

## Step 1: Shrink

First the script takes the original image (normally a TIFF, recreated here as a JPEG @ 669x502 pixels)

```ps1
magick convert sxms169_1_2_5-19.tif[0] -resize 669x502 .\sxms169_1_2_5-19.jpg
```

![Original Image](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/sxms169_1_2_5-19.jpg)

## Step 2: Enlarge and blur

Blurs the image by scaling down to 5% the original size, and then back up to half the original size.

```ps1
magick convert sxms169_1_2_5-19.tif[0] -sample 5% -resize 1000% \
    -resize 669x502 .\sxms169_1_2_5-19-blur.jpg
```

![Original Image - Blurred](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/sxms169_1_2_5-19-blur.jpg)

## Step 3: Trim

This image is then trimmed using ImageMagick's built in Trim function.

```ps1
magick convert sxms169_1_2_5-19.tif[0] -sample 5% -resize 1000% -fuzz 15% \
    -trim -resize 669x502 .\sxms169_1_2_5-19-blur-trim.jpg
```

![Original Image - Blurred & Trimmed](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/sxms169_1_2_5-19-blur-trim.jpg)

## Step 4: Slice

Then, this image is sliced into 100px strips

```ps1
magick convert sxms169_1_2_5-19.tif[0] -sample 5% -resize 1000% -fuzz 15% -trim \
    +repage -crop 100x -resize 30x502 ./scratch/sxms169_1_2_5-19-blur-trim_%d.jpg
```

![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim_0.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim_1.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim_2.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim_3.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim_4.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim_5.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim_6.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim_7.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim_8.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim_9.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim_10.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim_11.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim_12.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim_13.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim_14.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim_15.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim_16.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim_17.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim_18.jpg)

## Step 5: Re-trim

Each of these strips can then be trimmed again, any strip made up of just the background grey will be reduced to a 1x1 pixel.

```ps1
magick convert sxms169_1_2_5-19.tif[0] -sample 5% -resize 1000% -fuzz 15% -trim \
    +repage -crop 100x -resize 30x502 -bordercolor '#8B9093' -border 1x1 -fuzz 10% \
    -trim ./scratch/sxms169_1_2_5-19-blur-trim-strip_%d.jpg
```

![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim-strip_0.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim-strip_1.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim-strip_2.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim-strip_3.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim-strip_4.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim-strip_5.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim-strip_6.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim-strip_7.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim-strip_8.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim-strip_9.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim-strip_10.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim-strip_11.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim-strip_12.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim-strip_13.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim-strip_14.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim-strip_15.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim-strip_16.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim-strip_17.jpg) ![](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/scratch/sxms169_1_2_5-19-blur-trim-strip_18.jpg)

## Step 6: Maths

ImageMagick allows us to get the geometry for the trim that first happened on the blurred image.

```ps1
> magick convert sxms169_1_2_5-19.tif[0] -sample 5% -resize 1000% -fuzz 15% -trim \
    -format %wx%h%O info:

1859x1672+1096+529
```

Understanding how we have cut up the size of the image allows us to know where the gap now is between the artefact and the swatch.  The 14th slice is empty, so new geometry should be: 1300x1672+1096+529

```ps1
magick convert sxms169_1_2_5-19.tif[0] -sample 5% -resize 1000% \
    -crop 1300x1672+1096+529 -resize 10000x502 .\sxms169_1_2_5-19-blur-trim-crop.jpg
```

![Original Image - Blurred & Cropped](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/sxms169_1_2_5-19-blur-trim-crop.jpg)

## Step 7: Another Trim

This can now be trimmed again to make sure that the geometry does not include any additional background.

```ps1
> magick convert sxms169_1_2_5-19.tif[0] -sample 5% -resize 1000% \
    -crop 1300x1672+1096+529 -bordercolor '#8B9093' -border 1x1 -fuzz 10% \
    -trim -format %wx%h%O info:

1223x1672+1097+530
```

The first step scaled the blurred copy to half the size of the original image (for performance), so we now double our geometry, add a bit of padding, and apply the crop to the original file.

```ps1
magick convert sxms169_1_2_5-19.tif[0] -crop 2546x3444+2144+1010 \
    -bordercolor '#8B9093' -border 1x1 -fuzz 10% -trim -resize 1000000x502 \
    .\sxms169_1_2_5-19-crop.jpg
```

![Original Image - Cropped](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/sxms169_1_2_5-19-crop.jpg)

## All together now

Obviously, this is achievable in fewer steps in the final script, as many of these steps can be joined into one command.

```ps1
$output = magick convert sxms169_1_2_5-19.tif[0] -quiet -sample 5% \
    -resize 1000% -write ./scratch/sxms169_1_2_5-19.bmp -fuzz 17% -trim \
    -format '%wx%h%O' -write info: -quiet +repage -crop 50x -bordercolor '#8B9093' \
    -border 1x1 -fuzz 10% -trim ./scratch/sxms169_1_2_5-19-blur_%d.bmp
```

This command produces the blurred file for future trimming, the original trimmed geometry and the trimmed version of each of the slices of the image.

The final version (v6) of the script can be found here: [cropImages.v6.ps1](http://users.sussex.ac.uk/~sm826/Journal/2017-11-06/cropImages.v6.ps1)
