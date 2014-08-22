%%%
%%%This function displays thumbnail representations of the most highly
%%%ranked images in an XML structure.  The quantity of displayed images nad
%%%the fielname of the confidence meaurement can be specified, but will
%%%default to all the images (in order of rank) and 'eegconfidence' by
%%%default.  If not specifed, the current directory is assumed to house the
%%%image files.  Either the name of an XML file can be given, in which case
%%%it is read in and converted to a matlab structure, or an already
%%%converted to matlab XML structure can be specified (see
%%%convertXML2XMLstruct.m for how this can be done).
%%%
%%%[imagehandle] = displayrankedimages(XMLstruct,imagedirectory,qty2show,fieldname);
%%%
%%%Last modified March 2009, EAP

function [imagehandle] = displayrankedimages(XMLstruct,imagedirectory,qty2show,fieldname)

imagehandle = 0;

%%%By default assume that you are using the eeg confidend
if nargin < 4; 
    fieldname = 'eegconfidence';
    %fieldname = 'confidence';%if default is computer vision confidence
end
%%%
%%%By default assume images are located in the current directory
if nargin < 2; imagedirectory = cd; end
%%%
%%%If given an actual XML file it must first be converted to a form that
%%%Matlab can easily understand
if ischar(XMLstruct)
    if strcmp(XMLstruct(1,end-3:end),'.xml')
        XMLstruct = convertXML2XMLstruct(XMLstruct);
    else
        disp('XMLstruct not recognized as matlab structure or xml filename (need .xml ext)');
        return;
    end
end
%%%
%%%How many images are listed as entries in the XML
numentries = size(XMLstruct.object_info,2);
%%%
%%%By default assume that what is to be shown is every image in the XML
%%%file, unless that is more than 100, than just use 100
if nargin < 3; qty2show = numentries; end
if qty2show > 100; 
    disp('Too many images to show, just showing top 100');
    qty2show = 100; 
end

%%%
%%%Create a blank (square) background that will hold all the thumbnails
blankheight = 800;
blankwidth = 1200;
whichcolor = 256;%zero is black, 256 is white
blankdepth = 3;%for color
background = createmonochromaticimage(blankwidth, blankheight, whichcolor, blankdepth);

%%%
%%%Determine how big each thumbnail should be (put 5 pixels between columns
%%%and rows), and determine how many rows/columns of thumbnails that will
%%%require.  Make each thumbnail square.
%%%The thumbnail mosaic width is 1.5 times its height.
pixel_buffer = 5;
numrows      = round(sqrt(qty2show/1.5));
%numrows      = ceil(sqrt(qty2show/1.5));
numcolumns   = ceil(qty2show / numrows);
%numcolumns   = ceil(sqrt(qty2show));
%numrows      = numcolumns;

thumb_wd     = floor((blankwidth - pixel_buffer*(numcolumns - 1))/numcolumns);
thumb_ht     = floor((blankheight - pixel_buffer*(numrows - 1))/numrows);
thumb_wd     = floor(min([thumb_wd thumb_ht]));
thumb_ht     = thumb_wd;

%%%
%%%Now determin the x-y coordinates of each of the locations in the big
%%%images where the thumbnails will be located; (1,1) is the upper left
%%%corner of the big image.
thumbnailslot = zeros(qty2show,2);
row_counter = 1;
col_counter = 1;
col_location = 1;
for k=1:qty2show
    thumbnailslot(k,:) = [row_counter col_counter];
    col_location = col_location + 1;
    if col_location > numcolumns
        col_location = 1;
        row_counter = row_counter + thumb_ht + pixel_buffer;
        col_counter = 1;
    else
        col_counter = col_counter + thumb_wd + pixel_buffer;
    end    
end

%%%
%%%Get the highest ranked image names
[TopImages] = TopXMLimages(XMLstruct,qty2show,fieldname);
%%%
%%%Load each of those images, resize them to fit into the current empty
%%%thumbnail slot and add them to the display.
% [pathstr,name,ext,versn] = fileparts(file);
% info = imfinfo([pathstr name],ext(2:end));
%%%Create background for the thumbnail(s)
thumb_background = createmonochromaticimage(thumb_wd, thumb_ht, 256, 3);
method = 'nearest';
%method = 'bilinear';
for k=1:qty2show    
    %%%Read in the image
    image_name = fullfile(imagedirectory,TopImages{k,1});
    img = imread(image_name);    
    %%%If in black and white need to convert to a color encoding
    if size(img,3) == 1
        RGB = cat(3,img,img,img); clear img
        img = RGB; clear RGB;
    end    
    %%%Determine how big this image is, and then determine how much it will
    %%%need to be shrunk so that its largest dimension will fit into a
    %%%thumbnail area.
    scalefactor = max([size(img,1)/thumb_ht size(img,2)/thumb_wd]);    
    %%%Shrink as necessary
    %b = imresize(img,floor([size(img,1)/scalefactor size(img,2)/scalefactor]),method);   
    b = imresize_local(img,1/scalefactor,method);   
    %%%
    if size(b,1)>size(thumb_background,1)
        disp(['The thumbnail is ',int2str(size(b,1)-size(thumb_background,1)),' pixels too big, it will be cropped']); 
    end
    %%%Overlay onto the thumbnail background
    [newimage] = overlayimageAonB(b,thumb_background);
    %%%
    %%%Put the thumbnail into the big image
    background(thumbnailslot(k,1):(thumbnailslot(k,1)-1+thumb_ht),...
        thumbnailslot(k,2):(thumbnailslot(k,2)-1+thumb_wd),:) = newimage;
    clear image_name img b newimage scalefactor
end

%%%Show the thumbnails.
imagehandle = figure; imshow(background);

imagehandle = background;

%%%
%%%Output the final image as a .jpg
savequestion = input('Should file be saved? [y/n] ','s');
if strcmp(savequestion,'yes') || strcmp(savequestion,'y')
    outputfilename = [XMLstruct.file_name,'_top',int2str(qty2show),'_mosaic.jpg'];
    spots = strfind(outputfilename,'/');
    if isempty(spots)~=1
        outputfilename = outputfilename(1,(spots(end)+1):end);
    end
    imwrite(background,outputfilename,'jpg');
end

