%%%
%%%This function generates a mosaic of thumbnails of all the RSVP target
%%%chips listed in an output XML file (only 24 chips are shown per 
%%%mosaic, and as many mosaics as necessary are thus created).
%%%
%%%You can give it either the name of the XML file, in which case a matlab
%%%structure is created from the file (see convertXML2XMLstruct.m), or you
%%%can give it a matlab structure already created from the xml file.
%%%
%%%It is assumed that the xml data will already have ground truth
%%%information contained in each image node specifying whether or not that
%%%image was a target (unless otherwise specified this field is assumed to
%%%be named 'groundTruth').
%%%
%%%imagedirectory => location of the image files that were shown.  If not
%%%specified they are assumed to be in the current matlab working
%%%directory.
%%%
%%%[output] = showTargetthumbnails(XMLstruct,imagedirectory,GTfieldname);
%%%
%%%Last modified March 2009, EAP

function [output] = showTarget_thumbs(XMLstruct,imagedirectory,GTfieldname)

%%%
%%%Default is to start with image with the highest score
if nargin < 3
    GTfieldname = 'groundTruth';
end
%%%
%%%Default is to assume you are in the directory where the images are
%%%stored
if nargin < 2
    imagedirectory = cd;
end
%%%
%%%If necessary, convert the XML file into a structure matlab can use
%%%easily handle
if isstruct(XMLstruct)~=1
    xmlfilename = XMLstruct; clear XMLstruct;
    XMLstruct = convertXML2XMLstruct(xmlfilename);
end
%%%
%%%Confirm that the status of each image as target/distracter is contained
%%%in the xml data.
if isfield(XMLstruct.object_info{1,1},GTfieldname)~=1
    output = [];
    disp('No Ground truth information available');
    return;
end

%%%Get the filenames of each of the target RSVP images.
fieldnames{1,1} = 'file_name';
fieldnames{2,1} = GTfieldname;
stringflag = [1 0];
[output] = getXMLstructfieldvalue(XMLstruct,fieldnames,stringflag);

%%%We are assuming that a value of 1 means that this image was a true
%%%positive.
flagvalue = 1;
%%%Get the image filenames, elimining any file path aspect from the names
imagenames = output(cell2mat(output(:,2))==flagvalue,1);
numTargets = size(imagenames,1);
for k=1:numTargets
    spots = strfind(imagenames{k,1},'/');
    if isempty(spots)~=1
        imagenames{k,1} = imagenames{k,1}(1,(spots(end)+1):end);
    end
end

%%%
%%%Each mosaic will be 815 by 1220, and be compose of 4 rows and 6 columns
%%%of thumbnails showing the target images, ie each thumbnail will be
%%%200x200.
blankheight = 815; blankwidth  = 1225;
whichcolor  = 256;%zero is black, 256 is white
blankdepth  = 3;%for color
thumb_wd    = 200; thumb_ht    = 200;
method      = 'nearest';%Method used to resized the images for the thumbnails
pixel_buffer = 5;%number of pixels between thumbnails
%%%
%%%Create a blank (square) background that will hold all the thumbnails
background = createmonochromaticimage(blankwidth, blankheight, whichcolor, blankdepth);
%%%Create a blank backgound for the thumbnails.
thumb_background = createmonochromaticimage(thumb_wd, thumb_ht, 256, 3);
%%%
%%%This tells for each of the 24 thumbnails in the mosaic, their x-y
%%%coordinates
thumbnailslot = [reshape(repmat([1:205:815],6,1),24,1) repmat([1:205:1220]',4,1)];
%%%
%%%Make as many mosaics as is necessary to show all the target images
current_image  = 1;%thumbnail currently being placed
for k=1:numTargets
    %%%
    %%%Read in the target image
    image_name = fullfile(imagedirectory,imagenames{k,1});
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
    b = imresize_local(img,1/scalefactor,method);   
    %%%
    if size(b,1)>size(thumb_background,1)
        disp(['The thumbnail is ',int2str(size(b,1)-size(thumb_background,1)),' pixels too big, it will be cropped']); 
    end
    %%%Overlay onto the thumbnail background
    [newimage] = overlayimageAonB(b,thumb_background);
    
    %%%Now put the thumbnail into the current mosaic image
    background(thumbnailslot(current_image,1):(thumbnailslot(current_image,1)-1+thumb_ht),...
        thumbnailslot(current_image,2):(thumbnailslot(current_image,2)-1+thumb_wd),:) = newimage;        
    %%%
    %%%Increment the counter (which tells how many images are currently in
    %%%this mosaic).
    current_image = current_image + 1;
    %%%If you need to starting filling a new mosaic, save the current one
    %%%to a figure and start filling a new one    
    if (current_image > 24) || (k==numTargets)
        current_image = 1;
        h = figure; imshow(background);
        background = createmonochromaticimage(blankwidth, blankheight, whichcolor, blankdepth);
    end    
end















