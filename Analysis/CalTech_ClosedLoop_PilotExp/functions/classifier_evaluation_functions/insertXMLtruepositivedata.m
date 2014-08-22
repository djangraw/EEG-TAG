
%%%This function takes known groundtruth data and uses it to add an entry
%%%to an XML file that specifies whether each of the chips do (or do not)
%%%contain that kind of target.
%%%
%%%Need to include .xml in the xml filename.
%%%
%%%The name of the XML field that contains this data can be specified (the
%%%default name is truepositivestatus).
%%%
%%%The xml field value denoting a chip that contains a target is by default
%%%zero (zero indicating a chip for which the presence of a target is
%%%unknown, one indicating a chip known to contain a target, and two
%%%indicating a chip without a target).  All of these values can
%%%be specified in the 'labelvalue' input (a 1x3 row vector).
%%%
%%%This ground truth data can take several forms:
%%%1.)  Text file that lists the names of chips that have been determined
%%%to contain truth information, for this option use GTmode = 1;
%%%
%%%2.)  A text file that lists the x-y coordinates of known targets.  The
%%%size of the chips must also be specified.  The code then compares the
%%%coordinate of each chip to determine whether or not the specified target
%%%locations are contained within each of the chips, for this option use
%%%GTmode = 0, and the input chipsize must be included.
%%%
%%%3.) (GTmode = 2)  A text file that lists the x-y coordinates of known targets.  
%%%An error distance must also be specified.  The code then compares the
%%%coordinate of each chip to determine whether or not the euclidean distance
%%%between the cartesian coordinates of each chip are within the error
%%%distance.  If so, the chip is classied as a true positive, if not it is
%%%a negative.  For this option use GTmode = 2, and the 4th input
%%%(chipsize) will be used as the error distance.
%%%
%%%4.) (GTmode = 3).  In this mode the ground truth text files specifies
%%%a rectangular area that surounds each target. Each GT pt specified as:
%%%[xcoorupLftCorner ycoorupLftCorner width(xdirection) height(ydirection)]
%%%Each chip is then compared to these areas, if the chip overlaps any of
%%%these areas, that locatinos is classified as true positive.  If overlaps
%%%none of the gt sites, it is listed as a false positive.
%%%
%%%labelvalue => row vector of three values: 
%%%     1st is value if unknown status
%%%     2nd is value if target
%%%     3rd is value if known to be nontarget/distracter
%%%
%%%Last modified May 2009, EAP
%%%
%%%Need to input an XML struct that matlab can analyze, this can be
%%%obtained using the convertXML2XMLstruct.m function.

function [XMLstruct] = insertXMLtruepositivedata(XMLstruct,GTfilename,GTmode,chipsize,fieldname,labelvalue)

if nargin < 2
    disp('Must input at least the XML filename and the truth data filename');
    return;
end
%Default values
%%%
%%%format for labelvalue: [-1=>unknown, 1=>target, 0=>distracter]
if nargin < 6; labelvalue = [-1 1 0]; end
if nargin < 5; fieldname = ['truepositivestatus']; end
if nargin < 3; GTmode = 0; end

if GTmode == 0
    if nargin == 2
        disp('Chip size not specified, assuming 500x500');
        chipsize = 500;
    end
end

%%%Ensure it doesn't have the requested field name already
%%%If it does, ask if user wants to overwrite.
% overwriteflag = 0;
% if isfield(XMLstruct.object_info{1},fieldname)
%     disp('The requested XML field name already exists in the XML');
%     overwritequest = input('The existing data will be overwritten, continue? [y/n]? ','s');
%     if strcmp(overwritequest,'y') || strcmp(overwritequest,'yes')
%         overwriteflag = 1;
%     else
%         return;
%     end
% end

%%%How many entries there are in the XML file
numentries = size(XMLstruct.object_info,2);

%%%
%%%Use the truth data to add in the new XML field appropriately.
switch GTmode
   case 0%Comparing chip locations to known target coordinates
       %%%Load the truth data
       GTdata = load([GTfilename]);
       %%%For each XML field, see if that chip contains a known target
       for k=1:numentries
           %%%Check to see if the x- and y-coordinates of any target fall
           %%%within the area of this chip
           %(min(abs(str2double(XMLstruct.object_info{k}.position_x)-GTdata
           %(:,1))) <= 0.5*chipsize) && (min(abs(str2double(XMLstruct.object_info{k}.position_y)-GTdata(:,2))) <= 0.5*chipsize)
           distances = [GTdata(:,1)-str2double(XMLstruct.object_info{k}.position_x) str2double(XMLstruct.object_info{k}.position_y)-GTdata(:,2)];
           distances = abs(distances);
           if (max(sum(distances<=(0.5*chipsize),2)) >= 2)
               %%%If so, set the entry to the positive tag
               XMLstruct.object_info{k} = setfield(XMLstruct.object_info{k},fieldname,num2str(labelvalue(1,2)));
           else
               %%%If no targets in this chip, set to the negative tag
               XMLstruct.object_info{k} = setfield(XMLstruct.object_info{k},fieldname,num2str(labelvalue(1,3)));
           end
       end
   case 1%Comparing names of chip entries to known target chip names
       %%%Load the truth data
       fid = fopen(GTfilename);
       TextEntries = textscan(fid, '%s%*[^\n]');
       fclose(fid);
       GTdata = TextEntries{1}; clear TextEntries
       %%%For each chip field, see if its name overlaps with any of the
       %%%known target chips
       for k=1:numentries
           for z=1:size(GTdata,1)
               s = strfind(XMLstruct.object_info{k}.file_name,GTdata{z});
               if isempty(s)
                   %%%If it isn't a target chip
                   XMLstruct.object_info{k} = setfield(XMLstruct.object_info{k},fieldname,labelvalue(1,3));
               else
                   %%%If it is a target chip
                   XMLstruct.object_info{k} = setfield(XMLstruct.object_info{k},fieldname,labelvalue(1,2));
                   break;
               end
           end
           clear s
       end
       %%%
    case 2
        %%%Rather than looking to see if the chip contains a true positive
        %%%site anywhere, in this mode the image chip only counts as a true
        %%%positive if the target is within a specified distance of the
        %%%center of the chip.
        errordistance = chipsize;
        %%%
        %%%Load the truth data
       GTdata = load(GTfilename);
       %%%For each XML field, see if that chip contains a known target
       for k=1:numentries
           %%%Find the distance between the center of the chip and the
           %%%nearest of all the ground truth sites.
           x_coor = str2double(XMLstruct.object_info{k}.position_x);
           y_coor = str2double(XMLstruct.object_info{k}.position_y);
           euclidean_distance = (min(sum((GTdata - repmat([x_coor y_coor],size(GTdata,1),1)).^2,2)))^0.5;
           %%%Compare the closest ground truth site to the center of the chip
           if (euclidean_distance <= errordistance)
               %%%If so, set the entry to the positive tag
               XMLstruct.object_info{k} = setfield(XMLstruct.object_info{k},fieldname,num2str(labelvalue(1,2)));
           else
               %%%If no close to the center of this chip, set to the negative tag
               XMLstruct.object_info{k} = setfield(XMLstruct.object_info{k},fieldname,num2str(labelvalue(1,3)));
           end
       end
       %%%
   case 3%Comparing chip locations to known target areas
        %%%Load the truth data
        GTdata = load(GTfilename);
        %%%
        %%%For each chip determine which GT sites it overlaps with, the
        %%%size of that overlap, and the distance of that overlap to
        %%%the center of the chip
        coorfieldname{1,1} = 'position_x';
        coorfieldname{2,1} = 'position_y';
        [coordinates] = getXMLstructfieldvalue(XMLstruct,coorfieldname);%[x y coordinates]
        [overlap distances] = ChipAreaVsGTarea(coordinates,chipsize,GTdata);
        %%%
        %%%For each XML field, see if that chip contains a known target
       for k=1:numentries           
           %%%
           %%%If there is any nonzero between that chip and any GT sites,
           %%%classify that chip as a True Positive
           if (sum(overlap(k,:)) > 0)
               %%%If so, set the entry to the positive tag
               XMLstruct.object_info{k} = setfield(XMLstruct.object_info{k},fieldname,num2str(labelvalue(1,2)));
           else
               %%%If no targets in this chip, set to the negative tag
               XMLstruct.object_info{k} = setfield(XMLstruct.object_info{k},fieldname,num2str(labelvalue(1,3)));
           end
       end
    %%%In case of confusions
    otherwise
      disp('Unknown GTmode.')
      return;
end
