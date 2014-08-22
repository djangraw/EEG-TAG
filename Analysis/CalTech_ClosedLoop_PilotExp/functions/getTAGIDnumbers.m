%%%
%%%For a given list of image names, this function compares those to the
%%%images in the TAG graph and returns the corresponding TAG ID number for
%%%each image (in the correct order).
%%%
%%%This is done for the TAG graph3.
%%%
%%%[TAGids] = getTAGIDnumbers(ImageNames);
%%%
%%%Last modified Feb 2010, EAP

function [TAGids] = getTAGIDnumbers(ImageNames)

%%%
TAGids = zeros(length(ImageNames),1);
%%%
%%%this is the ordering of images used in the TAG graph
load TAGimageOrdering%variable name is TAGFileList
%%%
%%%Break up the image names into components specifying the specific caltech
%%%101 category, and specific filename
[categorydistribution file_list] = CalTech101categories(ImageNames);
%%%
%%%For each image, compare to the TAG image list and find where it falls.
T = strcat(file_list(:,1),['_'],file_list(:,2));%formatting of names used for the TAG graph
%%%
for k=1:size(ImageNames,1)
    TAGids(k,1) = strmatch(T{k},TAGFileList,'exact');
end%TAGFileList(TAGids)


