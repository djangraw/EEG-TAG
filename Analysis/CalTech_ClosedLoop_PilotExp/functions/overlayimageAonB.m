
%%%This function overlays one image (image A) on another (image B) by
%%%centering and replacing the data in the center of B (which is larger
%%%than A) with image A.
%%%
%%%[newimage] = overlayimageAonB(imageA,imageB);
%%%
%%%Last modified Dec 2008, EAP

function [newimage] = overlayimageAonB(imageA,imageB)

newimage = imageB;

if (size(imageA,3) ~= size(imageB,3))
    disp('Must be same type of images, can''t overlay');
    return;
end

if sum(size(imageA) == size(imageB)) == 3
    %disp('Images same area, just using foreground image');
    newimage = imageA;
    return;
end

%%Image range contans the pixels from the image that will get overlayed on
%%the background.  imagerange = [1strow lastrow; firstcol lastcol]
%%%Blank range contains similar info, but this is the section of the
%%%background that is going to be overlayed with the image (such that the
%%%overlayed image is centered).
imagerange  = zeros(2,2);
blankrange  = zeros(2,2);
%%%
%%%If the image is too big in one dimension, you'll need to crop some out.
%%%Otherwise you need to determine how much to offset the overlayed image
%%%so that it is centered.
imagewidth  = size(imageA,2);
imageheight = size(imageA,1);

blankwidth  = size(imageB,2);
blankheight = size(imageB,1);

if imageheight == blankheight
    imagerange(1,:) = [1 imageheight];
    blankrange(1,:) = [1 size(imageB,1)];
else    
    if imageheight <= blankheight
        imagerange(1,:) = [1 imageheight];    
        blankrange(1,:) = [ceil(abs(blankheight-imageheight)/2) blankheight-1-floor(abs(blankheight-imageheight)/2)];
    else
        disp('Image too tall for background, cropping excess');
        imagerange(1,:) = [abs(floor((blankheight - imageheight)/2)) imageheight-1-abs(ceil((blankheight - imageheight)/2))];
        blankrange(1,:) = [1 size(imageB,1)];
    end
end
if imagewidth == blankwidth
    imagerange(2,:) = [1 imagewidth];
    blankrange(2,:) = [1 size(imageB,2)];
else    
    if imagewidth <= blankwidth
        imagerange(2,:) = [1 imagewidth];
        blankrange(2,:) = [ceil(abs(blankwidth-imagewidth)/2) blankwidth-1-floor(abs(blankwidth-imagewidth)/2)];
    else
        disp('Image too wide for background, cropping excess');
        imagerange(2,:) = [abs(floor((blankwidth - imagewidth)/2)) imagewidth-1-abs(ceil((blankwidth - imagewidth)/2))];    
        blankrange(2,:) = [1 size(imageB,2)];
    end
end
%%%
%%%Replace the center of the background with the actual image
newimage([blankrange(1,1):blankrange(1,2)],[blankrange(2,1):blankrange(2,2)],:) = imageA([imagerange(1,1):imagerange(1,2)],[imagerange(2,1):imagerange(2,2)],:);

