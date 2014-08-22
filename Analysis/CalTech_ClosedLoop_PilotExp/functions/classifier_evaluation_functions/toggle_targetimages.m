%%%
%%%This function toggles through RSVP images classified as true positives.
%%%
%%%You can give it either the name of the XML file, in which case a matlab
%%%structure is created from the file (see convertXML2XMLstruct.m), or you
%%%can give it a matlab structure already created from the xml file.
%%%
%%%It is assumed that the xml data will already have ground truth
%%%information contained in each image node specifying whether or not that
%%%image was a target (unless otherwise specified this field is assumed to
%%%be named 'groundTruth').  The variable is GTfieldname.
%%%
%%%imagedirectory => location of the image files that were shown.  If not
%%%specified they are assumed to be in the current matlab working
%%%directory.
%%%
%%%[image_handle] = toggle_targetimages(XMLstruct,imagedirectory,GTfieldname);
%%%
%%%Last modified March 2009 EAP

function [image_handle] = toggle_targetimages(XMLstruct,imagedirectory,GTfieldname)

%%%
%%%By default assume that the node field is called groundTruth
if nargin < 3; 
    GTfieldname = 'groundTruth';
end
%%%Confirm that the status of each image as target/distracter is contained
%%%in the xml data.
if isfield(XMLstruct.object_info{1,1},GTfieldname)~=1
    image_handle = [];
    disp('No Ground truth information available');
    return;
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
        image_handle = [];
        return;
    end
end

%%%
%%%Get a list of all the image filenames and their status as a
%%%target/nontarget image
%%%Get the filenames of each of the target RSVP images.
fieldnames{1,1} = 'file_name';
fieldnames{2,1} = GTfieldname;
stringflag = [1 0];
[output] = getXMLstructfieldvalue(XMLstruct,fieldnames,stringflag);

%%%
%%%We are assuming that a value of 1 means that this image was a true
%%%positive.
flagvalue = 1;
%%%
%%%Get the image filenames, eliminating any file path aspect from the names
imagenames = output(cell2mat(output(:,2))==flagvalue,1);
numTargets = size(imagenames,1);
for k=1:numTargets
    spots = strfind(imagenames{k,1},'/');
    if isempty(spots)~=1
        imagenames{k,1} = imagenames{k,1}(1,(spots(end)+1):end);
    end
end

%%%
%%%Now allow user to toggle through all the target images.
startimage = 1;
[image_handle] = show_images(imagenames,imagedirectory,startimage);