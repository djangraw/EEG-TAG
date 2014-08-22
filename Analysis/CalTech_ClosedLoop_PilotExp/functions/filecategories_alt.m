%%%
%%%Given a list of Caltech 101 filenames, this function determines the
%%%distribution of target categories in that list.  It also returns a
%%%complete list of all the files as a cell matrix (first column being the
%%%category, and second column being the file name).
%%%
%%%The list should be a cell array.
%%%
%%%The filenames should have the form of: category_xxxx_filename_xxxx, such
%%%as: category_ibis_filename_image_0058.jpg
%%%
%%%[categorydistribution file_list] = filecategories(filelist);
%%%
%%%Last modified July 2009, EAP

function [categorydistribution file_list] = filecategories(filelist)

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
   
%%%This finds how many of each category there are in this list of images.
[All_Categories I J] = unique(file_list(:,1));
category_distribution = zeros(size(All_Categories,1),1);
for k=1:size(All_Categories,1)
    category_distribution(k,1) = sum(strcmp(All_Categories{k,1},file_list(:,1)));
end

%%%Organize the results for each category for output
categorydistribution      = cell(size(All_Categories,1),2);
categorydistribution(:,1) = All_Categories;
categorydistribution(:,2) = num2cell(category_distribution);


%%%
%%%Here we are going to show the results
[Y,I] = sort(category_distribution,'descend');
disp('These are the top 5 most prevelent categories');
for k=1:min(length(I),5)
    fprintf('Category: %s with %1.0f images \n',All_Categories{I(k)},category_distribution(I(k)));
end

%%%
%%%Get a distribution of the images that will be shown in the 1000 EEG
%%%image set
imagedistribution  = zeros(size(All_Categories,1),1);
for k=1:size(imagedistribution,1)
    imagedistribution(k,1) = sum(J==k);
end
bar(imagedistribution)
set(gca,'FontSize',8)
axis([0 size(imagedistribution,1)+2 0 max(category_distribution)+1]);
set(gca,'XTick',[1:(size(imagedistribution,1))])
set(gca,'XTickLabel',All_Categories);
xticklabel_rotate;



