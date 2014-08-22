%%%
%%%This function returns the highest ranked number of images from an
%%%XMLstruct (this is the kind of XML structure that has been read
%%%into Matlab from an XML file, see convertXML2XMLstruct.m).  If
%%%NumTopTargets not specified (or 0) all image names are return in order
%%%of rank (highest ranked to lowest ranked).
%%%
%%%[TopImages] = TopXMLimages(XMLstruct,NumTopTargets,confidencefieldname);
%%%
%%%XMLstruct => matlab XML structure, if given an XML filename, the XML
%%%structure will be created automatically.
%%%
%%%NumTopTargets => how many images will be returned (optional input,
%%%default is to return all images ranked highest to lowest).
%%%
%%%TopImages => will be a cell array of length NumTopTargets
%%%
%%%Last modified Feb 2009 EAP

function [TopImages] = TopXMLimages(XMLstruct,NumTopTargets,confidencefieldname)

if nargin < 3
	confidencefieldname = 'eegconfidence';
end

%%%
%%%If you don't already have an matlab XML structure, create it from the
%%%XML file.
if isstruct(XMLstruct) == 0
    XMLstruct = convertXML2XMLstruct(XMLstruct);
end
%%%
numXMLentries = size(XMLstruct.object_info,2);
%%%
%%%Return all the filenames (in order of rank) if desired.
if (nargin == 1) || (NumTopTargets<=0)
    NumTopTargets = numXMLentries;
end
%%%
%%%Load up the names of each of the images and what the corresponding EEG
%%%scores were.
fieldnames{1,1} = 'file_name';
fieldnames{2,1} = confidencefieldname;
stringflag = [1 0];
[output] = getXMLstructfieldvalue(XMLstruct,fieldnames,stringflag);
%%%
%%%Sort by score and return
[Y,I] = sort(cell2mat(output(:,2)),'descend');
%%%
TopImages = output(I(1:NumTopTargets),1);
%%%
%%%Eliminate any file path aspect from the filenames. 
for k=1:size(TopImages,1);
    spots = strfind(TopImages{k,1},'/');
    if isempty(spots)~=1
        TopImages{k,1} = TopImages{k,1}(1,(spots(end)+1):end);
    end
end


