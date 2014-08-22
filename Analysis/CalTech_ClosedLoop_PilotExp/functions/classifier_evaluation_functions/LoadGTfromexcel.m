%%%This function allows you to copy a column of excell cells that contain
%%%both the x and y-coordinates of Ground Truth data into matlab, which
%%%then converts that to a text file that has two columns of numbers: first
%%%being the x-coordinate and the 2nd being the y-coordinate.
%%%
%%%[coordinates] = LoadGTfromexcel(filename);
%%%filename: optional (requested if not provide), name of output text file.
%%%
%%%Last modified Feb 2009 EAP

function [coordinates] = LoadGTfromexcel(filename)

if nargin == 0
    filename = input('Enter the name of the GT file (don''t include .txt) ', 's');
    filename = [filename,'.txt'];
end

coordinates = [];
inputcoordinates = true;

while inputcoordinates
    disp('_____________________________________________________________');
    disp('Copy and paste the desired cells from excel.');
    disp('Should be a single column of cells that contain both the x and y values');
    disp('Just hit enter if no more to add');
    newcoordinates = input('Use brackets to surround pasted values ');
    
    coordinates = [coordinates; newcoordinates];
    
    if isempty(newcoordinates);
        inputcoordinates = false;
    end
    
    clear newcoordinates    
end


createGroundTruth(filename,coordinates);

