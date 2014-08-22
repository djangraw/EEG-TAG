%%%
%%%This function shows RSVP images in the order of the EEG rank.
%%%If known, the status of the image as a True positive is indicated.
%%%You can give it either the name of the XML file, in which case a matlab
%%%structure is created from the file (see convertXML2XMLstruct.m), or you
%%%can give it a matlab structure already created from the xml file.
%%%
%%%startimage => optional (default is 1), is the first image shown (in
%%%descending order by EEG rank).
%%%
%%%imagedirectory => location of the image files that were shown.  If not
%%%specified they are assumed to be in the current matlab working
%%%directory.
%%%
%%%[output] = toggleEEGscoredimages(XMLstruct,imagedirectory,startimage);
%%%
%%%Last modified March 2009 EAP

function [image_handle] = toggleEEGscoredimages(XMLstruct,startimage,imagedirectory)

%%%Default is to start with image with the highest score
if nargin < 3
    startimage = 1;
end
%%%Default is to assume you are in the directory where the images are
%%%stored
if nargin < 2
    imagedirectory = cd;
end

%%%If necessary, convert the XML file into a structure matlab can use
%%%easily handle
if isstruct(XMLstruct)~=1
    xmlfilename = XMLstruct; clear XMLstruct;
    XMLstruct = convertXML2XMLstruct(xmlfilename);
end

%%%
%%%Get the names of the images in order of their rank
qty2show = 0;%get all names
fieldname = 'eegconfidence';
[TopImages] = TopXMLimages(XMLstruct,qty2show,fieldname);
%%%
%%%If ground truth information is availabel for the images, you want to
%%%show that as well.
if isfield(XMLstruct.object_info{1,1},'groundTruth')
    allfieldnames = {fieldname;'groundTruth'};
    Scores = getXMLfieldvalue(XMLstruct,allfieldnames);
else
    Scores = -1*ones(size(TopImages,1),2);
    allfieldnames = {fieldname}; 
    Scores(:,1) = getXMLfieldvalue(XMLstruct,allfieldnames);
end
Scores = sortrows(Scores,-1);

showNext = 1;
current_image = startimage;
while showNext ~= 0
    image_handle = figure;    
    %%%Read in the image
    image_name = fullfile(imagedirectory,TopImages{current_image,1});
    img = imread(image_name);  
    %%%Display that image
    h2 = imshow(img);    
    title({[TopImages{current_image,1}];
        ['Image Number ', int2str(current_image),'; ',...
        fieldname,': ',num2str(Scores(current_image,1)),...
        '; ground truth status: ',num2str(Scores(current_image,2))]})
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
end
