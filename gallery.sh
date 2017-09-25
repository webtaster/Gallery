#!/bin/bash
#
# Simple thumbnail picture gallery script.  With some Imagemagick transformations.
#
# 17/8/14  J McDonnell
# 17/9/17  J McDonnell many updates
#

# Shrink videos if set to 1, leave them at raw size otherwise
# See the avconv command for the target resolution.
VIDREDUCE=0

# Target images will be this percentage in size of the raw image
PIC_REDUCE=35

# Image thumbs will be this percentage in size of the raw image
PIC_THUMB_REDUCE=7

# If no other source could be found for a picture caption, this string will be used
DEFAULT_PIC_CAPTION="Camera: James"


title=$1
if [[ -z $title ]]
then
   echo "First argument missing (title)"
   exit
fi


subtitle=$2
if [[ -z $subtitle ]]
then
   echo "No subtitle supplied (second argument)"
   subtitle=""
fi



zipfile="$title.zip"
targetdir="./website"
zipfile="$title.zip"



###############################################################################
#
# Create web site directory and index.html file
#
###############################################################################

echo Creating index.html file...

mkdir -p $targetdir
index="$targetdir/index.html"

cat > $index <<%
<html>
<font face=arial size=6>
<h3>$title</h3>
<h4>$subtitle</h4>
<p>Click on a thumbnail to download the full size image</p><br>
%


#
# Pass through pictures. Create thumnail images of each picture, and reduced size
# images of each picture (ignore videos for now).
#


#for picture in $(ls | egrep -i "jpg|jpeg" | egrep -v "mp4$|txt$")
for picture in $(ls | egrep -i "jpg$|jpeg$|info" | egrep -v "mp4$|txt$")
do
   echo
   echo Processing file $picture


   # If this "picture" file name ends in "header", write its contents into the main index.html
   # file as a heading and skip to the next loop
   if [[ $picture =~ info ]]
   then
      header=$(cat $picture)
      echo writing header $header
      echo "<hr><h5>$header</h5>" >> $index
      continue
   fi


   thumbpic="thumb_$picture"
   targetpic="target_$picture"


   ########################################################################################
   # Create thumbnail and reduced size target image for picture, unless they exist already
   ########################################################################################
   if [[ ! -f "$targetdir/$thumbpic" || ! -f "$targetpic.html" ]]
   then

      echo Creating thumbnail for image $picture

      # Pictitle will be the thumb caption.  pic_caption will be the picture caption
      thumb_caption=""
      pic_caption=""
      date=""


      # If a txt file exists for picture and is not empty, use the contents as (or
      # add the contents to) the thumb and picture captions
      if [ -s $picture.txt ]
      then
         pic_caption="$(cat $picture.txt)"
         thumb_caption="$(cat $picture.txt)"
      else
         x=1
         #pic_caption="$date"
      fi



      # If the picture file name looks like a file downloaded from Facebook, and no captions
      # have already been set, set the captions as "Facebook picture"
      # Otherwise, obtain the picture date from the file name.
      # I don't know how to obtain the creation date from a Facebook picture.
      if [[ ! -z $(egrep '_[0-9]{17}_' <<< $picture) ]]
      then
         echo looks like a Facebook picture: $picture
         [[ -z $thumb_caption ]] && thumb_caption="Facebook picture"
         [[ -z $pic_caption   ]] && pic_caption="Facebook picture"
      else
         # Get date and time of picture into a string
         read year month day hour min <<< $(echo $picture | sed 's/20\(..\)\(..\)\(..\)_\(..\)\(..\).*$/\1 \2 \3 \4 \5/')
         date="$day/$month/$year $hour:$min"
      fi


      # If the picture caption is still empty at this point, ie. if there was no .txt
      # file and it is not an image from Facebook, give it the default caption
      [[ -z $pic_caption ]] && pic_caption=$DEFAULT_PIC_CAPTION


      # Finally, add the date to the picture caption, But not to the thumb caption, or it
      # looks too cluttered
      if [[ ! -z $date ]]
      then
         #thumb_caption="$pictitle $date"
         pic_caption="$pic_caption $date"
      fi

      # Okay add the header too, if there is one
      pic_caption="$pic_caption $header"

      #echo thumb caption: $thumb_caption
      #echo pic caption: $pic_caption

      #
      # Uncomment one of the four paragraphs below to achieve different effects.
      # (Only have one paragraph at a time uncommented).
      #


      # Option 1. Simple thumbnails with no effects.
      #echo convert "$picture" -resize 10% "$thumbpic"
      #convert "$picture" -auto-orient -resize 10% "$thumbpic"


      # Option 2. Create a thumb picture with a simple frame around it, no caption
      # And reduce the target image and put a frame around that also
      #echo -auto-orient montage -resize 10% -frame 5 -geometry +0+0 "$picture" "$thumbpic"
      #montage -auto-orient -resize ${PIC_THUMB_REDUCE}% -frame 5 -geometry +0+0 "$picture" "$thumbpic"
      #montage -auto-orient -resize ${PIC_REDUCE}% -frame 5 -geometry +0+0 "$picture" "$targetpic"

      if [[ $thumb_caption == "" ]]
      then
         montage -auto-orient -geometry 300x300  "$picture" -frame 5 -geometry +0+0 "$targetdir/$thumbpic"
      else
         montage -auto-orient -geometry 300x300   -pointsize 20  -label "$thumb_caption" "$picture" -frame 5 -geometry +0+0 "$targetdir/$thumbpic"
      fi

         

      # Option 3. Put a simple frame round each picture with a caption at the bottom (-label)
      #echo montage -resize 10% -pointsize 20 -label "$thumb_caption" "$picture" -frame 5 -geometry +0+0 "$thumbpic"
      #montage -auto-orient -resize  ${PIC_THUMB_REDUCE}% -pointsize 20 -label "$thumb_caption" "$picture" -frame 5 -geometry +0+0 "$thumbpic"
      #montage -auto-orient -resize  ${PIC_REDUCE}%       -pointsize 20 -label "$thumb_caption" "$picture" -frame 5 -geometry +0+0 "$targetpic"
      #montage -auto-orient -geometry 200x200   -pointsize 20  -label "$thumb_caption" "$picture" -frame 5 -geometry +0+0 "$thumbpic"
      montage -auto-orient -geometry 1500x1000 -pointsize 20  -label "$pic_caption"  "$picture" -frame 5 -geometry +0+0 "$targetdir/$targetpic"


      # Option 4. Put a "polaroid" effect on each picture, including a caption.  Picture is framed,
      # rotated with shadow.  If $angle is zero there is no rotation.

      # Note: the "-repage" is there to offet the rotated/"polaroided" within its actual
      # (unrotated) frame.  Without -repage, there is clipping where the shared/rotated 
      # image goes beyond the image border.
      #
      #convert -resize 10% $picture png:small.png
      #angle=$(($RANDOM % 20 - 10))
      ##angle=0
      #convert -auto-orient -set caption "$thumb_caption" small.png -pointsize 28 -background black -polaroid $angle -repage +10+5 png:polaroid.png
      #convert polaroid.png -background white -flatten $thumbpic
     
   fi



   ######################################################################### 
   # Add thumbnail and picture links to main index.html file
   ######################################################################### 

   # Add thumb picture to main index.html file
   echo "<a href=$targetpic.html><img src=$thumbpic alt=$thumbpic title=\"$thumb_caption\"></a>" >> $index

   # Create sub html file for this picture, containing the target image
   echo "Creating sub html $targetpic.html"
   echo "<h3><a href=./index.html>Return</a><br><h4>$pic_caption</h4><img src=$targetpic></a></h3>" > $targetdir/$targetpic.html




   ############################################################################### 
   # Check the picture file for GPS information and if found, add a link from the
   # main index.html file to the relecant coordinates in Openstreetmap
   ############################################################################### 

   gpsposition=$(exiftool -r -s -c "%10f" -GPSPosition $picture)

   if [ -n "$gpsposition" ]
   then
      echo "Found GPS information <$gpsposition> in picture $picture"
      link=$(awk '{print "http://openstreetmap.org/?mlat="$3"&mlon=-"$5}' <<< $gpsposition)
      #link=$(echo $gpsposition | awk '{print "http://www.google.co.uk/maps/place/"$3$4$5$6}')
      echo "<a target="_blank" href=$link>Map</a>" >> $index
   else
      #echo No GPS information found in picture $picture
      x=1
   fi





done

rm -f polaroid.png small.png


# Create zipfile of all pics.  Works fine but de-implemented for now
#if [ ! -f "$targetdir/$zipfile" ]
#then
#   zip "$targetdir/$zipfile" $(ls | egrep -i "jpg$|jpeg$" | grep -v thumb)
#fi

# Create link to zipfile of all pics
#size=$(ls -lh "$targetdir/$zipfile" | awk '{print $5}')
#echo "<br><br><p>Download all pictures -->  <a href=\"$zipfile\">\"$zipfile\"</a> ($size)</p>" >> $index




#######################################################################
#
# Process video files if any.  Experimental.  Presents mp4 files straight
# in the browser, where they should play properly under HTML 5.
#
# It is difficult to retain the correct aspect ratio with mp4 files
# shrunk with avconv, so the $VIDREDUCE is set to 0 by default, preventing
# any attempt at reduction.  However, playing full size videos can take a
# fair chunk of upload bandwidth on your server, making playback
# occasionally jerky.
#
#######################################################################

if [[ -n $(ls | egrep "mp4$") ]]
then
   echo "*** Video files found ***"

   echo "<br><hr><p>Videos</p>" >> $index
   echo "<table>" >> $index


   for video in $(ls | egrep "mp4$" | egrep -v 'thumb_|small_')
   do
      echo Processing video file $video

      videolink="$video"

      # Reduce video file if option set
      if [[ $VIDREDUCE -eq 1 ]]
      then

         smallvideo="small_$video"

         if [[ ! -f $smallvideo ]]
         then
            echo "Reducing video $video"
            avconv -i $video -strict experimental -s 1280x720 -loglevel quiet $targetdir/$smallvideo
            #avconv -i $video -strict experimental -s 960x540 -loglevel quiet $targetdir/$smallvideo
            #avconv -i $video -strict experimental -s 320x200  $smallvideo
            #echo avconv -i $video -strict experimental -s 320x200  $smallvideo
         fi

         videolink=$smallvideo
      else
         # Copy video file (or the reduced size filem if video size has been reduced) into place
         cp -v -p --no-clobber -v $videolink $targetdir
      fi


      # Get descripton from txt file
      if [[ -s $video.txt ]]
      then
         description=$(cat $video.txt)
         echo Found video description: $description
      else
         touch $video.txt
      fi

      if [[ -z $description ]]
      then
         description="Video"
      fi



      # Create video thumbnail, unless it already exists
      thumbpic="thumb_$video.png"
      if [[ ! -f "$targetdir/$thumbpic" ]]
      then
         echo creating thumbnail of video $thumbpic
         totem-video-thumbnailer $video "$targetdir/$thumbpic"
      fi



      echo "<tr><td><a href=$videolink><img src=$thumbpic alt=$thumbpic title=$video></a></td><td>$description</td></tr>" >> $index
      #echo "<tr><td><img src=$thumbpic alt=$thumbpic title=$video></td><td><a href=$video download>$description</a></td></tr>" >> $index


      echo Finished processing video $video

   done

   echo After video loop

   echo "</table>" >> $index

fi

echo "<br><font face=arial size=2>Updated on $(date).  <a href=https://github.com/webtaster/Gallery>Gallery.sh</a> run time $SECONDS seconds.<br><br></html>" >> $index
echo "<-- gallery.sh script, J McDonnell, https://github.com/webtaster/Gallery -->" >> $index



tar -cf $targetdir.tar $targetdir
#rm -r $targetdir

echo
echo Prepared website is in $targetdir.tar, ready for shipping to web server


