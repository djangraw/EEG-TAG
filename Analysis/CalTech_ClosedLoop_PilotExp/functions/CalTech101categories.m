%%%
%%%Given a list of filenames that relate to images from the Caltech 101
%%%database, this function determines the specific, canoncial category and
%%%image name that each filename corresponds to.  This is in the form of a
%%%cell matrix (file_list: first column being the category, and second column being
%%%the file name). 
%%%Also determined is the distribution of how many images there are per
%%%target categories in that list (categorydistribution). This is returned
%%%on a per category basis for only the categories contained in the
%%%filelist, or on a per category basis for the specific set of categories
%%%contained in the in input list 'categorylist' (which is an optional
%%%input).
%%%
%%%The list of filenames and the list of categories (if provided) should be
%%%in the form of a cell array for the inputs.
%%%
%%%The filenames should have the form of: category_xxxx_filename_xxxx, such
%%%as: category_ibis_filename_image_0058.jpg
%%%
%%%[categorydistribution file_list] = CalTech101categories(filelist,categorylist);
%%%
%%%Last modified Nov 2009, EAP

function [categorydistribution file_list] = CalTech101categories(filelist,categorylist)

if nargin < 2; categorylist = []; end;

%%%Number of files
filelist = filelist(:);
numfiles = size(filelist,1);

%%%Get a list that breaks the information down into the specific
%%%categories, and the specific images.
file_list = cell(numfiles,2);
for k=1:numfiles
    K1 = strfind(filelist{k,1},'category_');%include this in case the name includes the file location as well as file name
    K2 = strfind(filelist{k,1},'_filename_');
    file_list{k,1} = filelist{k,1}(1,(K1+9):(K2-1));%category type
    file_list{k,2} = filelist{k,1}(1,(K2+10):end);%individual filename
    clear K1 K2
end
   
%%%
%%%If a specific list of categories is given, return the distribution of
%%%categories in that order
if isempty(categorylist)
    %%%This finds how many of each category there are in this list of images.
    [All_Categories I J] = unique(file_list(:,1));
    category_distribution = zeros(size(All_Categories,1),1);
    for k=1:size(All_Categories,1)
        category_distribution(k,1) = sum(strcmp(All_Categories{k,1},file_list(:,1)));
    end
    %%%
    %%%Organize the results for each category for output
    categorydistribution      = cell(size(All_Categories,1),2);
    categorydistribution(:,1) = All_Categories;
    categorydistribution(:,2) = num2cell(category_distribution);
else
    categorydistribution = cell(size(categorylist,1),2);
    categorydistribution(:,1) = categorylist;
    for k=1:size(categorylist,1)
        categorydistribution{k,2} = sum(strcmp(categorylist{k,1},file_list(:,1)));
    end
end

