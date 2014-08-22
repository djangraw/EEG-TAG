%%%
%%%Given a list of filename for a set of images, this function toggles
%%%through the images.
%%%
%%%Filelist => cell vector giving the filenames of the images to be shown
%%%
%%%startimage => optional (default is 1) which image of the vector to show
%%%first
%%%
%%%imagedirectory = optional (default is to asssume the current working
%%%directory) this is the name/location of the directory where the images
%%%are stored.
%%%
%%%[image_handle] = show_images(Filelist,imagedirectory,startimage);
%%%
%%%Last modified March 2009, EAP

function [image_handle] = show_images(Filelist,imagedirectory,startimage)

%%%Unless otherwise specified assume the images are located in teh current
%%%working directory
if nargin < 2
    imagedirectory = cd;
end
%%%Default is to start with the first image in the list
if nargin < 2 
    startimage = 1;
end

Filelist  = Filelist(:);
NumImages = size(Filelist,1);


showNext = 1;
current_image = startimage;
while showNext ~= 0
    image_handle = figure;    
    %%%Read in the image
    image_name = fullfile(imagedirectory,Filelist{current_image,1});
    img = imread(image_name);  
    %%%Display that image
    h2 = imshow(img);    
    title({[Filelist{current_image,1}]
        ['Image Number ',int2str(current_image)]})
    %%%Ask if want to look at the next image
    Next = input('Show next? [n or enter => next, p=>previous, q=>quit] ', 's');
    if strcmp(Next,''); Next = 'n'; end
    if strcmp(Next,'n')
        close(image_handle)
        current_image = current_image + 1;
    elseif strcmp(Next,'p')
        close(image_handle)
        current_image = current_image - 1;
    elseif strcmp(Next,'q')
        showNext = 0;
    end
    %%%If at end of list, start over
    if current_image > NumImages
        current_image = 1;
    end    
    %%%If before beginning, go to end
    if current_image < 1
        current_image = NumImages;
    end
end

